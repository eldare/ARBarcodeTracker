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
        serialQueue.async { [weak self] in
            guard let self = self else {
                print("Error: self is nil")
                return
            }
            do {
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
        var barcodePayload: String?
        var barcodeBoundingBox: CGRect?

        defer {
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

        print("Info: barcode detected: \(payload)")
        barcodePayload = payload
        barcodeBoundingBox = result.boundingBox
    }
}
