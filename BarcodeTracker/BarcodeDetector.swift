//
//  BarcodeDetector.swift
//  BarcodeTracker
//
//  Created by Eldar Eliav on 07/08/2020.
//  Copyright © 2020 none. All rights reserved.
//

import Foundation
import ARKit
import Vision

class BarcodeDetector {

    typealias SearchCompletion = (_ payload: String?, _ boundingBox: CGRect?, _ arFrame: ARFrame?) -> Void

    private var vnRequests = [VNRequest]()
    private var searchCompletion: SearchCompletion?
    private var isProcessing = false
    private var currentARFrame: ARFrame?
    private var serialQueue = DispatchQueue(label: "barcodeDetection",
                                            qos: .userInitiated)

    init(searchCompletion: @escaping SearchCompletion) {
        self.searchCompletion = searchCompletion
        setupBarcodeRequest()
    }

    func search(in arFrame: ARFrame) {
        // 7.
        // The Vision request will be made in a high priority serial queue, non blocking, of course.
        serialQueue.async { [weak self] in
            guard let self = self else {
                print("Error: self is nil")
                return
            }
            do {
                // 8.
                // We only process one Vision request at a time,
                // the rest will have to wait until this one is finished.
                self.isProcessing = true
                self.currentARFrame = arFrame
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: arFrame.capturedImage, options: [:])
                try requestHandler.perform(self.vnRequests)
            } catch {
                print("Error: perform failed with \(error)")
                self.isProcessing = false
            }
        }
    }

    private func setupBarcodeRequest() {
        let request = VNDetectBarcodesRequest(completionHandler: self.requestCompleted)
        request.symbologies = [.EAN13]
        self.vnRequests = [request]
    }

    private func requestCompleted(request: VNRequest, error: Error?) {
        // 9.
        // Vision finished, let's have a look if it found what we need.
        var barcodePayload: String?
        var barcodeBoundingBox: CGRect?

        defer {
            // 11.
            // Call a callback with the barcode payload & boundingBox (or nil, if nothing was found).
            // And also the relevant AR frame for additional plane processing.
            DispatchQueue.main.async {
                self.searchCompletion?(barcodePayload, barcodeBoundingBox, self.currentARFrame)
                self.isProcessing = false
                self.currentARFrame = nil
            }
        }

        guard let results = request.results,
            let result = results.first as? VNBarcodeObservation else {
            return
        }

        guard let payload = result.payloadStringValue else {
            print("Error: no payload detected")
            return
        }

        // 10.
        // Barcode found, we know it's payload
        // and what it can be found in the current AR frame.
        print("Info: barcode detected: \(payload)")
        barcodePayload = payload
        barcodeBoundingBox = result.boundingBox
    }
}
