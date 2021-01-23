/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import UIKit
import Vision
import Photos
import SwiftState

class DetectionViewController: UIViewController {
    @IBOutlet var faceView: FaceView!
    @IBOutlet weak var recordingLabel: UILabel!
    
    private let session = AVCaptureSession(),
                videoOutput = AVCaptureVideoDataOutput(),
                audioOutput = AVCaptureAudioDataOutput(),
                sessionQueue = DispatchQueue(label: "SessionQueue"),
                s3Dao = AWSS3DAO(),
                deviceUUID = UIDevice.current.identifierForVendor!.uuidString
    
    private var recorded = false,
                isRecording = false,
                previewLayer: AVCaptureVideoPreviewLayer!,
                sequenceHandler = VNSequenceRequestHandler(),
                photoData: Data?,
                videoWriter: AVAssetWriter?,
                videoWriterInput: AVAssetWriterInput?,
                audioWriterInput: AVAssetWriterInput?,
                sessionAtSourceTime: CMTime?
    
    // private let photoOutput = AVCapturePhotoOutput(),
    
    let videoOutputQueue = DispatchQueue(
        label: "Video data queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    let audioOutputQueue = DispatchQueue(
        label: "Audio data queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    var maxX: CGFloat = 0.0
    var midY: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    
    let sessionFetcher = SessionFetcher()
    var guardianSession: Session?
    var autofetcher: Timer?
    var stateMachine: StateMachine<GuardianState, NoEvent>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uploadFilesInDocumentDir()
        
        maxX = view.bounds.maxX
        midY = view.bounds.midY
        maxY = view.bounds.maxY
        
        configureCaptureSession()
        session.startRunning()
        setupStateMachine()
    }
    
    // MARK: - Accessing files
    func uploadFilesInDocumentDir() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            print("Listing current saved files..")
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            fileURLs.forEach({url in
                self.uploadDataToS3AndDelete(filePath: url)
            })
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    func uploadDataToS3AndDelete(filePath: URL) {
        let completionHandler: (URL) -> Void = { filePath in
            print("Deleting file at \(filePath)")
            if FileManager.default.fileExists(atPath: filePath.path) {
                do {
                    try FileManager.default.removeItem(at: filePath)
                    print("Removed \(filePath)")
                } catch {
                    print("Unable to remove \(filePath)")
                }
            } else {
                print("Unable to find file at \(filePath)")
            }
        }
        self.s3Dao.uploadData(filePath: filePath, completionHandler: completionHandler)
    }
}

// MARK: - FSM
extension DetectionViewController {
    @objc func refreshActiveSession() {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }
        // let deviceId = "BADC19DE-2E31-4B09-B6E2-85EBDFC778E6"
        self.sessionFetcher.getActiveSession(userId: "user", deviceId: deviceId) { session in
            if session != nil && self.stateMachine?.state != .guarding {
                self.stateMachine! <- .guarding
            }
        }
    }
    
    func setupStateMachine() {
        if (stateMachine == nil) {
            stateMachine = StateMachine<GuardianState, NoEvent>(state: .idle) { fsm in
                fsm.addRoute(.idle => .guarding)
                fsm.addRoute(.guarding => .idle)
                
                fsm.addHandler(.idle => .guarding) { context in
                    print("Now guarding!!!")
                    self.autofetcher?.invalidate()
                }
                
                fsm.addHandler(.guarding => .idle) { context in
                    self.startSessionAutoFetcher()
                }
            }
        }
        print("SM initial state \(stateMachine?.state)")
        if stateMachine!.state == .idle {
            startSessionAutoFetcher()
        }
    }
    
    func startSessionAutoFetcher() {
        autofetcher = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.refreshActiveSession), userInfo: nil, repeats: true)
    }
}

// MARK: - Human detection
extension DetectionViewController {
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter?.status == .writing
    }
    
    func detectedHumanIOS14(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNDetectedObjectObservation],
              let result = results.first else {
            return
        }
        let box = result.boundingBox
        faceView.boundingBox = convert(rect: box)
        DispatchQueue.main.async {
            self.faceView.setNeedsDisplay()
        }
        if (self.stateMachine?.state == .guarding) {
            if (!recorded && !isRecording) {
                isRecording = true
                print("Human detected, recording next 10s")
                sessionQueue.async {
                    // Start recording for the next 10 seconds.
                    // self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
                    // let formatter = DateFormatter()
                    // formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    let eventTimestamp: String = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let documentsDirectory = paths[0] as String
                    
                    let filePath = URL(fileURLWithPath: "\(documentsDirectory)/\(eventTimestamp)@@\(self.deviceUUID).mp4")
                    do {
                        if FileManager.default.fileExists(atPath: filePath.absoluteString) {
                            try FileManager.default.removeItem(at: filePath)
                            print("file removed")
                        }
                        print("Recorded video destination: \(filePath)")
                        self.videoWriter = try AVAssetWriter(outputURL: filePath, fileType: .mp4)
                        guard let writer = self.videoWriter else {
                            print("Unable to initialize AVAssetWriter")
                            return
                        }
                        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                            AVVideoCodecKey : AVVideoCodecType.h264,
                            AVVideoWidthKey : 1280,
                            AVVideoHeightKey : 720,
                            AVVideoCompressionPropertiesKey : [
                                AVVideoAverageBitRateKey : 2300000,
                            ],
                        ])
                        videoWriterInput.expectsMediaDataInRealTime = true
                        if writer.canAdd(videoWriterInput) {
                            writer.add(videoWriterInput)
                            self.videoWriterInput = videoWriterInput
                            print("video input added")
                        } else {
                            print("no video input added to AVAssetWriter")
                        }
                        
                        // add audio input
                        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                            AVFormatIDKey: kAudioFormatMPEG4AAC,
                            AVNumberOfChannelsKey: 1,
                            AVSampleRateKey: 44100,
                            AVEncoderBitRateKey: 64000,
                        ])
                        audioWriterInput.expectsMediaDataInRealTime = true
                        
                        if writer.canAdd(audioWriterInput) {
                            writer.add(audioWriterInput)
                            self.audioWriterInput = audioWriterInput
                            print("audio input added")
                        } else {
                            print("no audio input added to AVAssetWriter")
                        }
                        
                        writer.startWriting()
                        print("Video writer started")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [weak self] in
                            self?.videoWriterInput?.markAsFinished()
                            self?.audioWriterInput?.markAsFinished()
                            self?.videoWriter!.finishWriting {
                                self?.isRecording = false
                                self?.recorded = true
                                self?.sessionAtSourceTime = nil
                                print("Video writer finished")
                                self?.uploadDataToS3AndDelete(filePath: filePath)
                            }
                        })
                    } catch {
                        print("Error writing video: \(error)")
                    }
                    
                    /* This output cannot coexist with videoDataOutput
                     self.videoFileOutput.startRecording(to: filePath, recordingDelegate: self)
                     print("Starting the recording")
                     DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                     guard let this = self else {
                     print("WOW SELF IS GONE")
                     return
                     }
                     print("Stopping the recording")
                     this.videoFileOutput.stopRecording()
                     })
                     */
                }
            }
        }
    }
    
    func convert(rect: CGRect) -> CGRect {
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint)
        return CGRect(origin: origin, size: size.cgSize)
    }
}


// MARK: - Gesture methods

extension DetectionViewController {
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        // TODO: Do something
    }
}

// MARK: - Video Processing methods

extension DetectionViewController {
    
    func configureCaptureSession() {
        session.beginConfiguration()
        // Define the capture device we want to use
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front video camera available")
        }
        
        // Connect the camera to the capture session input
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
            print("Video device activated")
        } catch {
            fatalError(error.localizedDescription)
        }
        
        do {
            let audio = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
            let audioDevice = try AVCaptureDeviceInput(device: audio!)
            session.addInput(audioDevice)
            print("Audio device activated")
        } catch {
            print("No audio device available! \(error.localizedDescription)")
        }
        
        // Create the video data output
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = false
        
        audioOutput.setSampleBufferDelegate(self, queue: audioOutputQueue)
        
        
        // Add the video output to the capture session
        session.addOutput(videoOutput)
        session.addOutput(audioOutput)
        // session.addOutput(videoFileOutput)
        // session.addOutput(photoOutput)
        
        // let videoConnection = videoOutput.connection(with: .video)
        // videoConnection?.videoOrientation = .portrait
        session.commitConfiguration()
        
        // Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods
extension DetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let canWriteVideo = canWrite()
        if canWriteVideo && self.sessionAtSourceTime == nil {
            let sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter!.startSession(atSourceTime: sessionAtSourceTime)
            self.sessionAtSourceTime = sessionAtSourceTime
            print("Started session!")
            // TODO: Start a timer here to finish the session in 10s.
        }
        
        // print("CanWriteVid: \(canWriteVideo), Output: \(output), Audio ready? \(audioWriterInput?.isReadyForMoreMediaData)")
        if canWriteVideo, output == videoOutput, true == videoWriterInput?.isReadyForMoreMediaData {
            videoWriterInput!.append(sampleBuffer)
        } else if canWriteVideo, output == audioOutput, true == audioWriterInput?.isReadyForMoreMediaData {
            audioWriterInput!.append(sampleBuffer)
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if #available(iOS 14.0, *) {
            let detectHumanReq = VNDetectHumanRectanglesRequest(completionHandler: detectedHumanIOS14)
            do {
                try sequenceHandler.perform([detectHumanReq], on: imageBuffer)
            } catch {
                print("Error capturing video output sample: \(error.localizedDescription)")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}



// MARK: - Video Recording
/*
 extension DetectionViewController: AVCaptureFileOutputRecordingDelegate {
 
 func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
 let fileUrl = fileURL
 print("Did start recording to \(fileUrl)")
 }
 
 func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
 let fileUrl = outputFileURL
 print("Did finish recording to \(fileUrl)")
 }
 }
 */

// MARK: - Photo output
/*
 extension DetectionViewController: AVCapturePhotoCaptureDelegate {
 
 func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
 // Flash the screen to signal that the camera took a photo.
 print("Flashing...")
 
 self.previewLayer.opacity = 0
 UIView.animate(withDuration: 0.25) {
 self.previewLayer.opacity = 1
 }
 }
 
 func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
 print("Did finish processing")
 takingPhoto = false
 if let err = error {
 print("Error capturing photo: \(err)")
 } else {
 photoData = photo.fileDataRepresentation()
 }
 }
 
 func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
 print("Did finish capturing")
 if let error = error {
 print("Error capturing photo: \(error)")
 return
 }
 
 guard let photoData = photoData else {
 print("No photo data resource")
 return
 }
 
 self.tookPhoto = true
 /*
 PHPhotoLibrary.requestAuthorization { status in
 if status == .authorized {
 PHPhotoLibrary.shared().performChanges({
 let options = PHAssetResourceCreationOptions()
 let creationRequest = PHAssetCreationRequest.forAsset()
 creationRequest.addResource(with: .photo, data: photoData, options: options)
 
 }, completionHandler: { _, error in
 if let error = error {
 print("Error occurred while saving photo to photo library: \(error)")
 }
 })
 }
 }
 */
 }
 }
 */
