//
//  ViewController.swift
//  PracticeCoreData
//
//  Created by hyunsu on 2021/07/04.
//

import UIKit
import CoreData
import Combine

class ViewController: UIViewController {

    @IBOutlet weak var lastLabel: UILabel!
    
    let viewContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    let backgroundContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.newBackgroundContext()
    }()
    
    var cancellable: AnyCancellable!
    var person: Person?
    
    //MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        lastLabel.textColor = .green
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidSave),
                                               name: .NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    @objc func contextDidSave(notification: Notification) {
        viewContext.mergeChanges(fromContextDidSave: notification)
        print("generating notification!")
    }
  
    //MARK: - Combine
    @IBAction func changeLastPersonWithCombine(_ sender: Any) {
        let randomList = "abcdefghijklmn".map{String($0)}
        var randomName = ""
        for _ in 0..<10 {
            randomName += randomList.randomElement()!
        }
        
        viewContext.perform { [self] in
            person?.name = randomName
            try? viewContext.save()
        }
    }
    
    @IBAction func fetchLastPersonToSetLabelWithCombine(_ sender: Any) {
        let request = NSFetchRequest<Person>(entityName: "Person")
        viewContext.perform { [self] in
            person = try! request.execute().first
            self.cancellable = person?.publisher(for: \.name)
                .assign(to: \.text, on: self.lastLabel)
        }
    }

    //MARK: - Fetch
    @IBAction func fetchAllPerson(_ sender: Any) {
        let request = NSFetchRequest<Person>(entityName: "Person")
        var str = ""
        viewContext.perform { [self] in
            let list = try! request.execute()
            str = "People: \(list.count)"
            lastLabel.text = str
        }
    }
    @IBAction func fetchNation(_ sender: Any ) {
        let request = NSFetchRequest<Nation>(entityName: "Nation")
        var str = ""
        viewContext.perform { [self] in
            let list = try! request.execute()
            list.forEach {
                str += "\($0.country!): \($0.personCount) | \($0.persons!.count)\n"
            }
            lastLabel.text = str
        }
        
    }

    //MARK: - add
    @IBAction func addWithKorean(_ sender: Any) {
        addPerson(country: "korea", context: viewContext)
    }

    @IBAction func addWithAmerican(_ sender: Any) {
        addPerson(country: "america", context: viewContext)
    }

    @IBAction func addWithChinese(_ sender: Any) {
        addPerson(country: "china", context: viewContext)
    }
    
    func addPerson( country: String, context: NSManagedObjectContext) {
        context.perform  { [self ] in
            let person = Person(context: context)
            let request = NSFetchRequest<Nation>(entityName: "Nation")
            
            let list = try? context.fetch(request)
            list?.forEach{
                if $0.country == country {
                    person.nation = $0
                } else { return }
            }
            person.name = "vapor"
            try? context.save()
        }
    }
    
    @IBAction func setNation(_ sender: Any) {
        viewContext.perform { [ self] in
            let nationk = Nation(context: viewContext)
            nationk.country = "korea"
            let nationa = Nation(context: viewContext)
            nationa.country = "america"
            let nationc = Nation(context: viewContext)
            nationc.country = "china"
            try? viewContext.save()
            
        }
    }
    
    @IBAction func addKoreanUsingBackgroundContext(_ sender: Any) {
        backgroundContext.perform { [self] in
            addPerson(country: "korea", context: backgroundContext)
        }
    }
    
    //MARK:  - delete
    @IBAction func deleteAll(_ sender: Any) {
        deleteAllPerson()
        deleteAllNation()
    }

    func deleteAllPerson() {
        viewContext.perform { [ self] in
            let request = NSFetchRequest<Person>(entityName: "Person")
            var list = try? viewContext.fetch(request)
            list?.forEach {
                viewContext.delete($0)
            }
            list?.removeAll()
            
            try? viewContext.save()
        }
    }

    func deleteAllNation() {
        viewContext.perform { [ self] in
            let request = NSFetchRequest<Nation>(entityName: "Nation")
            var list = try? viewContext.fetch(request)
            list?.forEach {
                viewContext.delete($0)
            }
            list?.removeAll()
            
            try? viewContext.save()
        }
    }
    
    @IBAction func deleteLastPerson(_ sender: Any) {
        backgroundContext.perform { [self] in
            let request = NSFetchRequest<Person>(entityName: "Person")
            let person = try! backgroundContext.fetch(request).first!
            backgroundContext.delete(person)
            try? backgroundContext.save()
        }
    }
    @IBAction func deleteLastNation(_ sender: Any) {
        viewContext.perform { [self] in
            let request = NSFetchRequest<Nation>(entityName: "Nation")
            let person = try! viewContext.fetch(request).first!
            viewContext.delete(person)
            try? viewContext.save()
        }
    }
}




