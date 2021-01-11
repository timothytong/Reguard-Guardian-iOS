/// Copyright (c) 2020 Razeware LLC
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

import Foundation
import AWSS3

class AWSS3DAO {
  
  @objc var s3CompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
  @objc var progressBlock: AWSS3TransferUtilityProgressBlock?
  @objc lazy var transferUtility = {
    AWSS3TransferUtility.default()
  }()
  
  var progressView: UIProgressView! = UIProgressView()
  
  init() {
    self.progressBlock = {(task, progress) in
      DispatchQueue.main.async(execute: {
        if (self.progressView.progress < Float(progress.fractionCompleted)) {
          self.progressView.progress = Float(progress.fractionCompleted)
        }
      })
    }
    
    
  }
  
  @objc func uploadData(filePath: URL, completionHandler: @escaping (_ filePath: URL) -> Void) {
    var data: Data!
    do {
      data = try Data(contentsOf: filePath)
    } catch {
      print("Unable to retrieve data from \(filePath)")
    }
    let segments = filePath.absoluteString.split(separator: "/")
    let userId = "user" // TODO: update to user's real user id
    let objectKey = "users/\(userId)/events/\(segments[segments.count - 1])"
    
    self.s3CompletionHandler = { (task, error) -> Void in
      DispatchQueue.main.async {
        if let error = error {
          print("Failed with error: \(error)")
        }
        else if(self.progressView.progress != 1.0) {
          print("Error: Failed - Likely due to invalid region / filename")
        }
        else{
          print("Upload success!")
          completionHandler(filePath)
        }
      }
    }
    
    let expression = AWSS3TransferUtilityUploadExpression()
    expression.progressBlock = progressBlock
    
    DispatchQueue.main.async(execute: {
      self.progressView.progress = 0
    })
    
    
    
    transferUtility.uploadData(
      data,
      bucket: "guardian-event-captures",
      key: objectKey,
      contentType: "video/mp4",
      expression: expression,
      completionHandler: s3CompletionHandler).continueWith { (task) -> AnyObject? in
        if let error = task.error {
          print("Upload to S3 Error: \(error.localizedDescription)")
        }
        
        if let _ = task.result {
          print("Upload Starting for objectKey \(objectKey)!")
        }
        
        return nil;
      }
  }
}
