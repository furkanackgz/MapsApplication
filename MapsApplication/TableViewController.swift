//
//  TableViewController.swift
//  MapsApplication
//
//  Created by Furkan Açıkgöz on 19.03.2022.
//

import UIKit
import CoreData

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var titleList = [String]()
    var idList = [UUID]()
    var chosenId : UUID?
    var chosenTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(barButtonClicked))
        
        fetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: NSNotification.Name.init(rawValue: "Location Added"), object: nil)
    }
    
    @objc func barButtonClicked(){
        chosenTitle = ""
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenId = idList[indexPath.row]
        chosenTitle = titleList[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            let destination = segue.destination as! MapViewController
            destination.locationTitle = chosenTitle
            destination.locationId = chosenId
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Alternatively this title also can be id.
            let title = titleList[indexPath.row]
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationInfo")
            fetchRequest.predicate = NSPredicate(format: "title = %@", title)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let products = try context.fetch(fetchRequest)
                
                if products.count > 0 {
                    for product in products as! [NSManagedObject]{
                        if let title = (product.value(forKey: "title") as? String){
                            if title == titleList[indexPath.row] {
                                context.delete(product)
                                
                                titleList.remove(at: indexPath.row)
                                idList.remove(at: indexPath.row)
                                
                                self.tableView.reloadData()
                                
                                do{
                                    try context.save()
                                }catch{
                                    
                                }
                                
                                break
                            }
                        }
                    }
                }
            }catch{
                
            }
            
        }
    }
    
    @objc func fetch(){
        
        titleList.removeAll(keepingCapacity: false)
        idList.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationInfo")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let locations = try context.fetch(fetchRequest)
            
            if locations.count > 0 {
                for location in locations as! [NSManagedObject]{
                    if let title = location.value(forKey: "title") as? String{
                        titleList.append(title)
                    }
                    
                    if let id = location.value(forKey: "id") as? UUID{
                        idList.append(id)
                    }
                }
                
                tableView.reloadData()
            }
        }catch{
            print("error ")
        }
        
    }
    
}
