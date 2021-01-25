//
//  DocumentUploader.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/24/21.
//

import Foundation

class DocumentUploader {
    private let s3Dao = AWSS3DAO()
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
