//
//  HTTPClientTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension HTTPClient {
    
    final class Task {
        
        typealias CompletionHandler = (NSData?, NSURLRequest, NSHTTPURLResponse?, NSError?) -> Void
        typealias Parameters = [String: AnyObject]
     
        enum Method: String {
            case GET = "GET"
            case HEAD = "HEAD"
            case POST = "POST"
            case PUT = "PUT"
            case DELETE = "DELETE"
            
            private var encodesParameterInURL: Bool {
                switch self {
                case .GET, .HEAD, .DELETE:
                    return true
                default:
                    return false
                }
            }
        }
        
        enum Encoding {
            case URL
            case JSON
            
            func encode(URLRequest: NSMutableURLRequest, parameters: Parameters?) -> NSError? {
                if parameters == nil {
                    return nil
                }
                var error: NSError? = nil
                
                // set properly encoded parameters
                switch self {
                case .URL:
                    func query(parameters: [String: AnyObject]) -> String {
                        var components: [(String, String)] = []
                        for key in Array(parameters.keys).sort(<) {
                            let value: AnyObject! = parameters[key]
                            components += queryComponents(key, value)
                        }
                        
                        return (components.map{"\($0)=\($1)"} as [String]).joinWithSeparator("&")
                    }
                    
                    guard let method = Method(rawValue: URLRequest.HTTPMethod) where method.encodesParameterInURL else {
                        if URLRequest.valueForHTTPHeaderField("Content-Type") == nil {
                            URLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        }
                        URLRequest.HTTPBody = query(parameters!).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                        break
                    }
                    if let URLComponents = NSURLComponents(URL: URLRequest.URL!, resolvingAgainstBaseURL: false) {
                        URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(parameters!)
                        URLRequest.URL = URLComponents.URL
                    }
                case .JSON:
                    do {
                        let data = try NSJSONSerialization.dataWithJSONObject(parameters!, options: [])
                        URLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        URLRequest.HTTPBody = data
                    } catch let error1 as NSError {
                        error = error1
                    }
                }
                return error
            }
            
            func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
                var components: [(String, String)] = []
                if let dictionary = value as? [String: AnyObject] {
                    for (nestedKey, value) in dictionary {
                        components += queryComponents("\(key)[\(nestedKey)]", value)
                    }
                } else if let array = value as? [AnyObject] {
                    for value in array {
                        components += queryComponents("\(key)[]", value)
                    }
                } else {
                    components.appendContentsOf([(escape(key), escape("\(value)"))])
                }
                
                return components
            }
            
            func escape(string: String) -> String {
                let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
                return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
            }
        }

        
    }
    
}