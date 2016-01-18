//
//  WalletFetchRequest.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum WalletFetchRequestOrder: SQLiteRepresentable {
    
    case Ascending
    case Descending
    
    var representativeStatement: String {
        if self == .Ascending {
            return "ASC"
        }
        else {
            return "DESC"
        }
    }
    
}

class WalletFetchRequest<T: WalletFetchRequestProviderType> {
    
    let numberOfObjects: Int
    let incrementSize: Int
    let order: WalletFetchRequestOrder
    private var buckets: [Int: [T.ModelType]] = [:]
    private let logger: Logger
    private let provider: T
    
    // MARK: Fetch management
    
    func objectAtIndex(index: Int, completion: (T.ModelType?) -> Void) {
        objectsInRange(index...index) { objects in
            guard let objects = objects where objects.count > 0 else {
                completion(nil)
                return
            }
            completion(objects[0])
        }
    }
    
    func allObjects(completion: ([T.ModelType]?) -> Void) {
        objectsInRange(0..<numberOfObjects, completion: completion)
    }
    
    func objectsInRange(range: Range<Int>, completion: ([T.ModelType]?) -> Void) {
        logger.info("Asking for objects in range \(range)")
        guard incrementSize > 0 else {
            logger.error("Unable to fetch object(s) in range \(range): incrementSize is 0")
            completion(nil)
            return
        }
        guard (range.endIndex >= range.startIndex) && (range.endIndex <= numberOfObjects) else {
            logger.error("Unable to fetch object(s) in range \(range): only \(numberOfObjects) object(s) to return")
            completion(nil)
            return
        }
        guard let requiredIndexes = bucketIndexesForObjectsInRange(range) else {
            logger.error("Unable to fetch object(s) in range \(range): cannot determine required bucket indexes")
            completion(nil)
            return
        }
        
        // get missing bucket indexes
        let missingBucketIndexes = missingBucketIndexesForBucketIndexes(requiredIndexes)
        guard missingBucketIndexes.count > 0 else {
            let objects = bucketObjectsInRange(range, bucketIndexes: requiredIndexes)
            completion(objects)
            return
        }
        
        // fetch missing buckets
        fetchObjectsFromStoreAtBucketIndexes(missingBucketIndexes) { [weak self] success in
            guard let strongSelf = self else { return }
            
            guard success else {
                strongSelf.logger.error("Unable to fetch object(s) in range \(range): store cannot provide objects for missing bucket indexes \(missingBucketIndexes)")
                completion(nil)
                return
            }
            
            let objects = strongSelf.bucketObjectsInRange(range, bucketIndexes: requiredIndexes)
            completion(objects)
        }
    }
    
    // MARK: Utils
    
    private func bucketObjectsInRange(range: Range<Int>, bucketIndexes: Range<Int>) -> [T.ModelType]? {
        var objects: [T.ModelType] = []
        
        // add all first indexes
        let firstIndexes = Set(bucketIndexes.dropLast())
        for index in firstIndexes where buckets[index] != nil {
            objects.appendContentsOf(buckets[index]!)
        }
        
        // add objects of last bucket
        guard let lastIndex = bucketIndexes.last, lastObjects = buckets[lastIndex] else {
            return objects
        }
        let remainingRange = range.suffixFrom(firstIndexes.count * incrementSize)
        let remainingObjects = lastObjects.prefix(remainingRange.count)
        return objects + remainingObjects
    }
    
    private func bucketIndexesForObjectsInRange(range: Range<Int>) -> Range<Int>? {
        guard range.count > 0 else {
            return nil
        }
        return normalizeIndexToIncrementSize(range.startIndex)...normalizeIndexToIncrementSize(range.endIndex - 1)
    }
    
    private func normalizeIndexToIncrementSize(index: Int) -> Int {
        return index / incrementSize
    }
    
    private func missingBucketIndexesForBucketIndexes(indexes: Range<Int>) -> Set<Int> {
        var missingIndexes: Set<Int> = []
        
        indexes.filter({ buckets[$0] == nil }).forEach({ missingIndexes.insert($0) })
        return missingIndexes
    }
    
    // MARK: Store fetch management
    
    private func fetchObjectsFromStoreAtBucketIndexes(indexes: Set<Int>, completion: (Bool) -> Void) {
        guard indexes.count > 0 else {
            completion(true)
            return
        }
        guard let firstIndex = indexes.first else {
            logger.error("Unable to get first bucket index to fetch")
            completion(false)
            return
        }
        
        logger.info("Fetching objects from store for bucket index \(firstIndex), size \(incrementSize)")
        provider.fetchObjectsFromStoreFrom(firstIndex * incrementSize, size: incrementSize, order: order) { [weak self] objects in
            guard let strongSelf = self else { return }
            
            guard let objects = objects else {
                strongSelf.logger.error("Unable to fetch objects from store for bucket index \(firstIndex)")
                completion(false)
                return
            }
            
            // assign buckets
            strongSelf.logger.info("Got \(objects.count) objects from store for bucket index \(firstIndex)")
            strongSelf.buckets[firstIndex] = objects
            
            // fetch next objects
            let newIndexes = Set(indexes.dropFirst())
            strongSelf.fetchObjectsFromStoreAtBucketIndexes(newIndexes, completion: completion)
        }
    }
    
    // MARK: Initialization
    
    required init(provider: T, incrementSize: Int, order: WalletFetchRequestOrder, numberOfObjects: Int) {
        self.incrementSize = incrementSize
        self.numberOfObjects = numberOfObjects
        self.logger = Logger.sharedInstance(name: String(self.dynamicType))
        self.provider = provider
        self.order = order
        logger.info("New fetch request for objects of type \(String(T.ModelType.self)) with \(numberOfObjects) results")
    }
    
}