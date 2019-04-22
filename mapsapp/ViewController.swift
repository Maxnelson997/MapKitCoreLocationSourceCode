//
//  ViewController.swift
//  mapsapp
//
//  Created by Max Nelson on 4/11/19.
//  Copyright © 2019 Maxcodes. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    fileprivate let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.delegate = self

        segmentedControl.addTarget(self, action: #selector(switchType), for: .valueChanged)
        
    }
    
    fileprivate func addAnnotationToMap() {
        let annotation = MKPointAnnotation()
//        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.85, longitude: -122.4194)
        annotation.title = "Maxcodes Courses"
        annotation.subtitle = "Maxcodes YouTube iOS Content"
        annotation.coordinate = mapView.userLocation.coordinate
        mapView.addAnnotation(annotation)
    }

    @objc fileprivate func switchType() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satelliteFlyover
        case 2:
            mapView.mapType = .hybrid
        default:
            return
        }
    }
    
    @IBAction func pinAddress(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter Address", message: "We need your address for geocoding", preferredStyle: .alert)
        
        
        alertController.addTextField { (tf) in }
        
        let saveButton = UIAlertAction(title: "Pin Address", style: .default) { (action) in
            if let tf = alertController.textFields?.first {
                let addressText = tf.text!
                self.geocodeAndAnnotate(addressText: addressText)
            }
        }
        
        alertController.addAction(saveButton)
        
        present(alertController, animated: true)
    }
    
    
    
    fileprivate func geocodeAndAnnotate(addressText: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressText) { (placemarks, err) in
            if let err = err {
                print(err.localizedDescription); return
            }
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
        //// get directions
            let coordinates = placemark?.location?.coordinate
            let destinationInformation = MKPlacemark(coordinate: coordinates!)
            
            let startingPoint = MKMapItem.forCurrentLocation()
            let destinationPoint = MKMapItem(placemark: destinationInformation)
            
            let directionsReq = MKDirections.Request()
            directionsReq.transportType = .automobile
            directionsReq.source = startingPoint
            directionsReq.destination = destinationPoint
            
            let directions = MKDirections(request: directionsReq)
            directions.calculate(completionHandler: { (response, err) in
                if let err = err {
                    print(err.localizedDescription)
                    return
                }
                
                if let response = response {
                    guard let route = response.routes.first else { return }
                    let steps = route.steps
                    if !steps.isEmpty {
                        for step in steps {
                            print("next step:", step.instructions)
                        }
                    }
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                }
                
            })
            

        //// open in maps app
//            let coordinates = placemark?.location?.coordinate
//            let destinationInformation = MKPlacemark(coordinate: coordinates!)
//            let mapItem = MKMapItem(placemark: destinationInformation)
//
//            MKMapItem.openMaps(with: [mapItem], launchOptions: nil)
        
        //// pin address to map
//            let coordinates = placemark?.location?.coordinate
//            let newAnnotation = MKPointAnnotation()
//            newAnnotation.coordinate = coordinates ?? CLLocationCoordinate2D(latitude: 20, longitude: 20)
//            self.mapView.addAnnotation(newAnnotation)
        }
        
    }
    
}

extension ViewController: CLLocationManagerDelegate {

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red.withAlphaComponent(0.8)
        renderer.lineWidth = 8
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        let cluster = MKClusterAnnotation(memberAnnotations: memberAnnotations)
        cluster.title = "Coffee, Games and Clothes."
        cluster.subtitle = "a group of cool places."
        return cluster
    }

    fileprivate func setupMapSnapshot(annotation: MKAnnotationView) {
        let options = MKMapSnapshotter.Options()
        options.size = CGSize(width: 200, height: 200)
        options.mapType = .hybridFlyover
        let center = annotation.annotation?.coordinate ?? CLLocationCoordinate2D(latitude: 20, longitude: 20)
        options.camera = MKMapCamera(lookingAtCenter: center, fromDistance: 150, pitch: 60, heading: 0)
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { (snapshot, err) in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            if let snapshot = snapshot {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                imageView.image = snapshot.image
                annotation.detailCalloutAccessoryView = imageView
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 10, longitudinalMeters: 10)
        mapView.setRegion(region, animated: true)
        addAnnotationToMap()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
//        var marker = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation") as? MKMarkerAnnotationView
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
        marker.clusteringIdentifier = "coffee identifier"
        marker.glyphText = "Coffee"
        marker.canShowCallout = true
        marker.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "pin"))
        marker.rightCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "chevron"))
        setupMapSnapshot(annotation: marker)
        return marker
    }
}

