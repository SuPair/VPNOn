//
//  VPNDataManager+VPN.swift
//  VPN On
//
//  Created by Lex Tang on 12/5/14.
//  Copyright (c) 2014 LexTang.com. All rights reserved.
//

import CoreData
import VPNOnKit

extension VPNDataManager
{
    func allVPN() -> [VPN]
    {
        var vpns = [VPN]()
        
        let request = NSFetchRequest(entityName: "VPN")
        let sortByTitle = NSSortDescriptor(key: "title", ascending: true)
        let sortByServer = NSSortDescriptor(key: "server", ascending: true)
        let sortByType = NSSortDescriptor(key: "ikev2", ascending: false)
        request.sortDescriptors = [sortByTitle, sortByServer, sortByType]
        
        if let moc = managedObjectContext {
            if let results = (try? moc.executeFetchRequest(request)) as! [VPN]? {
                for vpn in results {
                    if vpn.deleted {
                        continue
                    }
                    vpns.append(vpn)
                }
            }
        }
        return vpns
    }
    
    func createVPN(
        title: String,
        server: String,
        account: String,
        password: String,
        group: String,
        secret: String,
        alwaysOn: Bool = true,
        ikev2: Bool = false,
        certificateURL: String?,
        certificate: NSData?
        ) -> VPN?
    {
        let entity = NSEntityDescription.entityForName("VPN", inManagedObjectContext: managedObjectContext!)
        let vpn = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext!) as! VPN
        
        vpn.title = title
        vpn.server = server
        vpn.account = account
        vpn.group = group
        vpn.alwaysOn = alwaysOn
        vpn.ikev2 = ikev2
        vpn.certificateURL = certificateURL
        
        var error: NSError?
        do {
            try managedObjectContext!.save()
            saveContext()
            
            if !vpn.objectID.temporaryID {
                VPNKeychainWrapper.setPassword(password, forVPNID: vpn.ID)
                VPNKeychainWrapper.setSecret(secret, forVPNID: vpn.ID)
                VPNKeychainWrapper.setCertificate(certificate, forVPNID: vpn.ID)
                
                if allVPN().count == 1 {
                    VPNManager.sharedManager.activatedVPNID = vpn.ID
                }
                return vpn
            }
        } catch var error1 as NSError {
            error = error1
            debugPrint("Could not save VPN \(error), \(error?.userInfo)")
        }
        
        return .None
    }
    
    func deleteVPN(vpn:VPN)
    {
        let objectID = vpn.objectID
        let ID = "\(vpn.ID)"
        
        VPNKeychainWrapper.destoryKeyForVPNID(ID)
        managedObjectContext!.deleteObject(vpn)
        
        var saveError: NSError?
        do {
            try managedObjectContext!.save()
        } catch var error as NSError {
            saveError = error
        }
        saveContext()
        
        if let activatedVPNID = VPNManager.sharedManager.activatedVPNID {
            if activatedVPNID == ID {
                VPNManager.sharedManager.activatedVPNID = nil
                
                var vpns = allVPN()
                
                if let firstVPN = vpns.first {
                    VPNManager.sharedManager.activatedVPNID = firstVPN.ID
                }
            }
        }
    }
    
    func VPNByID(ID: NSManagedObjectID) -> VPN?
    {
        var error: NSError?
        if ID.temporaryID {
            return .None
        }
        
        var result: NSManagedObject?
        do {
            result = try managedObjectContext?.existingObjectWithID(ID)
        } catch let error1 as NSError {
            error = error1
            result = nil
        }
        if let vpn = result {
            if !vpn.deleted {
                managedObjectContext?.refreshObject(vpn, mergeChanges: true)
                return vpn as? VPN
            }
        } else {
            debugPrint("Fetch error: \(error)")
            return .None
        }
        return .None
    }
    
    func VPNByIDString(ID: String) -> VPN?
    {
        if let URL = NSURL(string: ID) {
            if let scheme = URL.scheme {
                if scheme.lowercaseString == "x-coredata" {
                    if let moid = persistentStoreCoordinator!.managedObjectIDForURIRepresentation(URL) {
                        return VPNByID(moid)
                    }
                }
            }
        }
        return .None
    }
    
    func VPNByPredicate(predicate: NSPredicate) -> [VPN]
    {
        var vpns = [VPN]()
        var request = NSFetchRequest(entityName: "VPN")
        request.predicate = predicate
        
        var error: NSError?
        let fetchResults = managedObjectContext!.executeFetchRequest(request) as! [VPN]?
        
        if let results = fetchResults {
            for vpn in results {
                if vpn.deleted {
                    continue
                }
                vpns.append(vpn)
            }
        } else {
            debugPrint("Failed to fetch VPNs: \(error?.localizedDescription)")
        }
        
        return vpns
    }
    
    func VPNBeginsWithTitle(title: String) -> [VPN]
    {
        let titleBeginsWithPredicate = NSPredicate(format: "title beginswith[cd] %@", argumentArray: [title])
        return VPNByPredicate(titleBeginsWithPredicate)
    }
    
    func VPNHasTitle(title: String) -> [VPN]
    {
        let titleBeginsWithPredicate = NSPredicate(format: "title == %@", argumentArray: [title])
        return VPNByPredicate(titleBeginsWithPredicate)
    }
    
    func duplicate(vpn: VPN) -> VPN?
    {
        let duplicatedVPNs = VPNDataManager.sharedManager.VPNBeginsWithTitle(vpn.title)
        if duplicatedVPNs.count > 0 {
            let newTitle = "\(vpn.title) \(duplicatedVPNs.count)"
            
            VPNKeychainWrapper.passwordForVPNID(vpn.ID)
            
            return createVPN(
                newTitle,
                server: vpn.server,
                account: vpn.account,
                password: VPNKeychainWrapper.passwordStringForVPNID(vpn.ID) ?? "",
                group: vpn.group,
                secret: VPNKeychainWrapper.secretStringForVPNID(vpn.ID) ?? "",
                alwaysOn: vpn.alwaysOn,
                ikev2: vpn.ikev2,
                certificateURL: vpn.certificateURL,
                certificate: VPNKeychainWrapper.certificateForVPNID(vpn.ID)
            )
        }
        
        return .None
    }
}
