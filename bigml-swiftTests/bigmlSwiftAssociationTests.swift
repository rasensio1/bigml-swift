//
//  BigMLKitConnectorAssociationTests.swift
//  BigMLKitConnector
//
//  Created by sergio on 21/12/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

import XCTest
import bigmlSwift

class BigMLKitConnectorAssociationTests: BigMLKitConnectorBaseTest {

    func localAssociationRule(resId : String,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : ([[String : AnyObject]], [[String : AnyObject]]) -> ()) {
            
            self.connector!.getResource(BMLResourceType.Association, uuid: resId) {
                (resource, error) -> Void in
                
                if let resource = resource {
                    
                    let association = Association(jsonAssociation: resource.jsonDefinition)
                    
                    let prediction1 = association.associationSet(
                        argsByName,
                        options: ["byName" : true])
                    
                    let prediction2 = association.associationSet(
                        argsById,
                        options: ["byName" : false])

                    completion(prediction1, prediction2)
                    
                } else {
                    completion([], [])
                }
            }
    }
    
    func remotePrediction(fromResource : BMLResource,
        argsById : [String : AnyObject],
        completion : ([[String : AnyObject]]) -> ()) {
            
            self.connector!.createResource(BMLResourceType.Prediction,
                name: fromResource.name,
                options: ["input_data" : argsById],
                from: fromResource) { (resource, error) -> Void in
                    
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil)
                    
                    if let resource = resource?.jsonDefinition {
                        completion([[
                            "prediction" : resource["output"]!,
                            "probabilities" : resource["probabilities"]!,
                            "probability" : ((resource["probabilities"] as! [AnyObject]).first as! [AnyObject]).last!]])
                    } else {
                        completion([])
                    }
            }
    }
    
    func localAssociationRuleFromDataset(predictionType : BMLResourceType,
        dataset : BMLMinimalResource,
        argsByName : [String : AnyObject],
        argsById : [String : AnyObject],
        completion : ([[String : AnyObject]], [[String : AnyObject]]) -> ()) {
            
            self.connector!.createResource(BMLResourceType.Association,
                name: dataset.name,
                options: [:],
                from: dataset) { (resource, error) -> Void in
                    
                    if let error = error {
                        print("Error: \(error)")
                    }
                    XCTAssert(resource != nil && error == nil)
                    
                    if let resource = resource {
                        
                        self.localAssociationRule(resource.uuid,
                            argsByName: argsByName,
                            argsById: argsById) { (prediction1 : [[String : AnyObject]],
                                prediction2 : [[String : AnyObject]]) in
                                
                                completion(prediction1, prediction2)
                                
//                                self.remotePrediction(resource,
//                                    argsById: argsById) { (prediction : [[String : AnyObject]]) in
//                                        
//                                        self.connector!.deleteResource(predictionType,
//                                            uuid: resource.uuid) {
//                                                (error) -> Void in
//                                                XCTAssert(error == nil, "Pass")
//                                                completion(prediction1, prediction)
//                                        }
//                                }
                        }
                        
                    } else {
                        completion([], [])
                    }
            }
    }
    
    func testRemoteAssociation() {
        
        self.runTest("testRemoteIrisAssociation") { (exp) in
            
            self.localAssociationRule("567844288a318f6d750180b3",
                argsByName: [
                    "sepal length": 6.02,
                    "sepal width": 3.15,
                    "petal width": 1.51,
                    "petal length": 4.07],
                argsById: [
                    "000000": 6.02,
                    "000001": 3.15,
                    "000003": 1.51,
                    "000002": 4.07]) { (prediction1 : [[String : AnyObject]],
                        prediction2 : [[String : AnyObject]]) in
                        
                        print("P1: \(prediction1)")
                        
                        exp.fulfill()
            }
        }
    }

    func testIrisAssociation() {
        
        self.runTest("testIrisAssociation") { (exp) in
            
            self.localAssociationRuleFromDataset(BMLResourceType.Association,
                dataset: BigMLKitConnectorBaseTest.aDataset as! BMLMinimalResource,
                argsByName: [
                    "sepal length": 6.02,
                    "sepal width": 3.15,
                    "petal width": 1.51,
                    "petal length": 4.07],
                argsById: [
                    "000000": 6.02,
                    "000001": 3.15,
                    "000003": 1.51,
                    "000002": 4.07]) { (prediction1 : [[String : AnyObject]], prediction2 : [[String : AnyObject]]) in
                        
                        XCTAssert((prediction1[0]["item"] as! AssociationItem).name == "Iris-versicolor" &&
                            compareDoubles(prediction1[0]["score"] as! Double, d2: 0.0864))
                        XCTAssert((prediction2[0]["item"] as! AssociationItem).name == "Iris-versicolor" &&
                            compareDoubles(prediction2[0]["score"] as! Double, d2: 0.0864))
                        
                        exp.fulfill()
            }
        }
    }



}
