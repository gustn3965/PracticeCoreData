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
        let request: NSFetchRequest<NSFetchRequestResult> = Person.fetchRequest()
        request.resultType = .countResultType
        viewContext.perform { [self] in
            let count = try? viewContext.fetch(request).last
            lastLabel.text = "People: \(count!)"
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
            print("completed")
        }
        print("hello")
    }
    
    @IBAction func fetchPersonCountGroupedByAge() {
        viewContext.perform { [self] in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
            request.propertiesToGroupBy = ["age"]
            request.resultType = .dictionaryResultType
            
            let description = NSExpressionDescription()
            description.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "age")])
            description.name = "count"
            description.expressionResultType = .integer16AttributeType
            
            request.propertiesToFetch = ["age", description]
            
            let result = try? viewContext.fetch(request) as? [[String: Int]]
            var str = ""
            result!.forEach {
                str += "age: \($0["age"]!), count: \($0["count"]!)\n"
            }
            lastLabel.text = str
        }
    }

    //MARK: - add
    @IBAction func addWithKorean(_ sender: Any) {
        addPerson(country: "korea", by: viewContext)
    }

    @IBAction func addWithAmerican(_ sender: Any) {
        addPerson(country: "america", by: viewContext)
    }

    @IBAction func addWithChinese(_ sender: Any) {
        addPerson(country: "china", by: viewContext)
    }
    
    /// Create person who has random age and random name
    func addPerson( country: String, by context: NSManagedObjectContext) {
        context.perform  { 
            let randomList = "abcdefghijklmn".map{String($0)}
            var randomName = ""
            for _ in 0..<10 {
                randomName += randomList.randomElement()!
            }
            let person = Person(context: context)
            person.age = (20...25).randomElement()!
            
            let request = NSFetchRequest<Nation>(entityName: "Nation")
            let list = try? context.fetch(request)
            list?.forEach{
                if $0.country == country {
                    person.nation = $0
                } else { return }
            }
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
    @IBAction func setPersonRandomTo1000(_ sender: Any) {
        for _ in 0..<1000 {
            let country = ["korea","america","china"].randomElement()!
            addPerson(country: country, by: backgroundContext)
        }
    }
    
    @IBAction func addKoreanUsingBackgroundContext(_ sender: Any) {
        backgroundContext.perform { [self] in
            addPerson(country: "korea", by: backgroundContext)
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




