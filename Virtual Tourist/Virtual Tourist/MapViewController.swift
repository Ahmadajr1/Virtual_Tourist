//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Al Ramadhan on 18/01/2019.
//  Copyright © 2019 Ahmed Al Ramadhan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController,MKMapViewDelegate{
    
    var annotations = [MKPointAnnotation]()
    var pins = [Pin]()
    
    var dataController: DataController {
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        return appDelegate.dataController
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addWaypoint(touch:)))
        mapView.addGestureRecognizer(longGesture)
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pins = result
            PopulateMapWithPins(pins)
        }
    }
    
    @objc func addWaypoint(touch: UILongPressGestureRecognizer) {
        if touch.state == .began {
        let touchLocation = touch.location(in: mapView)
        let mapCoordinates = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = CLLocationDegrees(mapCoordinates.latitude)
        pin.longitude = CLLocationDegrees(mapCoordinates.longitude)
        try? dataController.viewContext.save()
        pins.append(pin)
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Latitude: \(String(format: "%.3f", pin.latitude)) Logtitude: \(String(format: "%.3f", pin.longitude))"
        annotations.append(annotation)
        self.mapView.addAnnotations(annotations)
        }
    }
    
    func PopulateMapWithPins(_ pins:[Pin]){
        self.mapView.removeAnnotations(annotations)
        for pin in pins{
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Latitude: \(String(format: "%.3f", pin.latitude)) Logtitude: \(String(format: "%.3f", pin.longitude))"
            annotations.append(annotation)
            self.mapView.addAnnotations(annotations)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .blue
            pinView!.rightCalloutAccessoryView = UIButton(type: .infoLight)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let lat = CLLocationDegrees((view.annotation?.coordinate.latitude)!)
        let long = CLLocationDegrees((view.annotation?.coordinate.longitude)!)
        for pin in pins{
            if pin.latitude == lat && pin.longitude == long{
                let object = UIApplication.shared.delegate
                let appDelegate = object as! AppDelegate
                appDelegate.pin = pin
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "PhotoAlbumCollectionViewController") as! PhotoAlbumCollectionViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

