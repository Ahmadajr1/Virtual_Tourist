//
//  FlickrApi.swift
//  Virtual Tourist
//
//  Created by Ahmed Al Ramadhan on 19/01/2019.
//  Copyright © 2019 Ahmed Al Ramadhan. All rights reserved.
//

import UIKit
import CoreData

class FlickrApi: UIViewController {
    
    
    var isDownloading:Bool = true
    
    var pinTotalNumberOfPhotos:Int = 0
    var pinPhotos:[Photo?] = []
    var numberOfPages = 1
    var page = 1
    
    var dataController: DataController {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.dataController
    }
    
    var pin: Pin {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.pin!
    }
    
    func bboxString() -> String {
        let minimumLon = max(pin.longitude - 1.0, (-180.0, 180.0).0)
        let minimumLat = max(pin.latitude - 1.0, (-90.0, 90.0).0)
        let maximumLon = min(pin.longitude
            + 1.0, (-180.0, 180.0).1)
        let maximumLat = min(pin.latitude + 1.0, (-90.0, 90.0).1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.flickr.com"
        components.path = "/services/rest"
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject],completionHandler: @escaping (_ success:Bool) -> Void) {
        
        let methodParameters = [
            "method": "flickr.photos.search",
            "api_key": "e6784206d95bd25f07da662d07c5af9e",
            "bbox": bboxString(),
            "safe_search": "safe_search",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "page": "\(page)"
        ]
        
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func displayError(_ error: String) {
                print(error)
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            
            
            guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult!)")
                return
            }
            
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                displayError("Cannot find key '\("photos")' in \(parsedResult!)")
                return
            }
            
            let pages = photosDictionary["pages"] as? Int
            if let pages = pages{
                self.numberOfPages = pages
                if self.page < self.numberOfPages{
                    self.page += 1
                } else{
                    self.page = 1
                }
            }
 
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\("photo")' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                displayError("No Photos Found. Search Again.")
                return
            } else {
                if photosArray.count <= 18{
                    self.pinTotalNumberOfPhotos = photosArray.count
                } else {
                    self.pinTotalNumberOfPhotos = 18
                }
                for i in 0..<self.pinTotalNumberOfPhotos{
                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    let photoTitle = photoDictionary["title"] as? String
                    guard let imageUrlString = photoDictionary["url_m"] as? String else {
                        displayError("Cannot find key '\("url_m")' in \(photoDictionary)")
                        return
                    }
                    let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        DispatchQueue.main.async{
                            let photo = Photo(context: self.dataController.viewContext)
                            let object = UIApplication.shared.delegate
                            let appDelegate = object as! AppDelegate
                            photo.pin = appDelegate.pin
                            photo.id = String(i)
                            photo.photo = imageData
                            self.pin.numberOfPhotos = Double(self.pinTotalNumberOfPhotos)
                            try! self.dataController.viewContext.save()
                        }
                    } else {
                        print("Image does not exist at \(imageURL!)")
                    }
                    completionHandler(true)
                }
            }
        }
        // start the task!
        task.resume()
    }
    
    
}




