//
//  ViewController.swift
//  MapsApplication
//
//  Created by Furkan Açıkgöz on 19.03.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    var locationTitle : String?
    var locationId : UUID?
    
    var latitude = Double()
    var longitude = Double()
    var region : MKCoordinateRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let keyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideTheKeyboard))
        view.addGestureRecognizer(keyboardGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if locationTitle != "" {
            self.saveButton.isHidden = true
            
            if let idString = locationId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationInfo")
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let locations = try context.fetch(fetchRequest)
                    
                    if locations.count > 0 {
                        for location in locations as! [NSManagedObject]{
                            if let title = location.value(forKey: "title") as? String{
                                nameTextField.text = title
                                
                                if let subTitle = location.value(forKey: "subTitle") as? String{
                                    noteTextField.text = subTitle
                                    
                                    if let latitude =  location.value(forKey: "latitude") as? Double{
                                        self.latitude = latitude
                                        
                                        if let longitude =  location.value(forKey: "longitude") as? Double{
                                            self.longitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                            annotation.title = title
                                            annotation.subtitle = subTitle
                                            annotation.coordinate = location
                                            mapView.addAnnotation(annotation)
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                            self.region = MKCoordinateRegion(center: location, span: span)
                                        }
                                    }
                                }
                            }
                            
                            
                            
                        }
                    }
                }catch{
                    
                }
                
                
            }
        }
        else{
            self.saveButton.isHidden = false
            self.saveButton.isEnabled = false
            self.nameTextField.text = ""
            self.noteTextField.text = ""
        }
    }
    
    @objc func hideTheKeyboard(){
        view.endEditing(true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locationTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            self.region = MKCoordinateRegion(center: location, span: span)
        }
        mapView.setRegion(self.region!, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reusableId = "AnnotationId"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reusableId)
        
        if annotationView == nil {
            
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reusableId)
            annotationView?.canShowCallout = true
            annotationView?.tintColor = .red
            
            let annotationButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = annotationButton
            
        }else{
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let targetLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        
        CLGeocoder().reverseGeocodeLocation(targetLocation) { placemarks, err in
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    
                    let placemark = MKPlacemark(placemark: placemarks[0])
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = self.locationTitle
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: launchOptions)
                    
                }
            }
        }
            
    }
    
    
    
    @objc func selectLocation(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            latitude = coordinates.latitude
            longitude = coordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            annotation.title = nameTextField.text
            annotation.subtitle = noteTextField.text
            mapView.addAnnotation(annotation)
        }
        
        self.saveButton.isEnabled = true
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let location = NSEntityDescription.insertNewObject(forEntityName: "LocationInfo", into: context)
        location.setValue(nameTextField.text, forKey: "title")
        location.setValue(noteTextField.text, forKey: "subTitle")
        location.setValue(latitude, forKey: "latitude")
        location.setValue(longitude, forKey: "longitude")
        location.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
        }catch{
            print("Object cannot be saved!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "Location Added"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    // calismiyor sebebini bul
    func alert(title : String, message : String){
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "Ok", style: .default) { UIAlertAction in
            
        }
        
        alert.addAction(okButton)
        
        self.present(alert, animated: true, completion: nil)
    }

}

