//
//  DiaryUseCase.swift
//  Diary
//
//  Created by 우롱차, RED on 2022/06/16.
//

import CoreData

protocol UseCase {
    associatedtype Element: DataModelable
    func create(element: Element) throws -> Element
    func read() throws -> [Element]
    func update(element: Element) throws
    func delete(element: Element) throws
}

final class DiaryUseCase: UseCase {
    
    let containerManager: ContainerManagerable
    lazy var context = containerManager.persistentContainer.viewContext
    lazy var diaryEntity = NSEntityDescription.entity(forEntityName: DiaryInfo.entityName, in: context)
    
    init(containerManager: ContainerManagerable) {
        self.containerManager = containerManager
    }
    
    private func filterDiaryData(key: UUID) throws -> [NSManagedObject] {
        let request: NSFetchRequest<DiaryData> = DiaryData.fetchRequest()
        let predicate = NSPredicate(format: "key = %@", key.uuidString)
        request.predicate = predicate
        let diarys = try context.fetch(request)
        let objectDiarys = diarys as [DiaryData]
        return objectDiarys
    }
    
    @discardableResult
    func create(element: DiaryInfo) throws -> DiaryInfo {
        let key = UUID()
        guard let diaryData = NSEntityDescription.insertNewObject(
            forEntityName: DiaryInfo.entityName,
            into: context
        ) as? DiaryData else {
            throw CoreDataError.createError
        }

        diaryData.title = element.title
        diaryData.body = element.body
        diaryData.date = element.date
        diaryData.key = key

        try context.save()
        
        return DiaryInfo(title: element.title, body: element.body, date: element.date, key: key)
    }
    
    func read() throws -> [DiaryInfo] {
        guard let diarys = try? context.fetch(DiaryData.fetchRequest()) else {
            throw CoreDataError.readError
        }
        var diaryInfoArray: [DiaryInfo] = []
        for diary in diarys {
            let diaryInfo = DiaryInfo(title: diary.title, body: diary.body, date: diary.date, key: diary.key)
            diaryInfoArray.append(diaryInfo)
        }
        return diaryInfoArray
    }
    
    func update(element: DiaryInfo) throws {
        guard let key = element.key else {
            throw CoreDataError.updateError
            }
        let diarys = try filterDiaryData(key: key)
        
        guard diarys.count > 0 else {
            throw CoreDataError.updateError
        }
        let diary = diarys[0]
        diary.setValue(element.title, forKey: "title")
        diary.setValue(element.body, forKey: "body")
        try context.save()
    }
    
    func delete(element: DiaryInfo) throws {
        let request: NSFetchRequest<DiaryData> = DiaryData.fetchRequest()
        guard let uuidString = element.key?.uuidString else {
            throw CoreDataError.deleteError
        }
        let predicate = NSPredicate(format: "key = %@", uuidString)
        request.predicate = predicate
        let result = try context.fetch(request)
        let resultArray = result as [DiaryData]
        guard resultArray.count > 0 else {
            throw CoreDataError.deleteError
        }
        context.delete(resultArray[0])
        try context.save()
    }
}
