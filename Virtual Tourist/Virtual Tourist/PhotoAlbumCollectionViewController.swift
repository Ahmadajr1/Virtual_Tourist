//
//  PhotoAlbumCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Al Ramadhan on 18/01/2019.
//  Copyright © 2019 Ahmed Al Ramadhan. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "FlickrImage"


class PhotoAlbumCollectionViewController: FlickrApi,UICollectionViewDataSource,UICollectionViewDelegate{
    
    @IBOutlet var collectionView: UICollectionView!
    
    
    var photoFetchedResultsController:NSFetchedResultsController<Photo>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        photoFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try! photoFetchedResultsController.performFetch()
        pinPhotos.removeAll()
        self.pinPhotos = Array(repeating:nil, count:Int(pin.numberOfPhotos))
        collectionView.reloadData()
        var counter = 0
        for photo in photoFetchedResultsController.fetchedObjects!{
            pinPhotos[counter] = photo
            counter += 1
            collectionView.reloadData()
        }
        
        if counter == Int(pin.numberOfPhotos){
            isDownloading = false
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(Refresh)), animated: true)
        self.navigationItem.setRightBarButton(UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(RetrieveNewCollection)), animated: true)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        setupFetchedResultsController()
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(SaveOrSharePhoto(touch:)))
        self.collectionView?.addGestureRecognizer(longGesture)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        if pinPhotos.isEmpty{
            downloadImages()
        }
        self.collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        photoFetchedResultsController = nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(pin.numberOfPhotos)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 8
        return CGSize(width: width/3, height: width/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        // Configure the cell
        let activityIndicator = cell.startAnActivityIndicator()
        
        if pinPhotos[indexPath.row]?.photo != nil{
            let photoData = pinPhotos[indexPath.row]!.photo!
            cell.photoImageView.image = UIImage(data: photoData)
        } else{
            cell.photoImageView.image = nil
        }
        if cell.photoImageView.image != nil && isDownloading == false{
            activityIndicator.stopAnimating()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isDownloading == false{
            let photoToBeDeleted = photoFetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(photoToBeDeleted)
            pin.numberOfPhotos -= 1
            try? dataController.viewContext.save()
            self.setupFetchedResultsController()
        }
    }
    
    
    @objc func SaveOrSharePhoto(touch: UILongPressGestureRecognizer) {
        
        let point = touch.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        if let index = indexPath{
            if touch.state == .began {
                let activityVC = UIActivityViewController(activityItems: [UIImage(data: (pinPhotos[index.row]?.photo)!)], applicationActivities: nil)
                activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                    if !completed {
                        return
                    }
                    else{
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                present(activityVC, animated: true)
            }
        }
    }
    
    func searchByLatLon(){
        let methodParameters = [
            "method": "flickr.photos.search",
            "api_key": "e6784206d95bd25f07da662d07c5af9e",
            "bbox": bboxString(),
            "safe_search": "safe_search",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1"
        ]
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        isDownloading = true
        displayImageFromFlickrBySearch(methodParameters as [String:AnyObject]){(success) -> Void  in
            DispatchQueue.main.async {
                self.setupFetchedResultsController()
            }
        }
    }
    
    func downloadImages(){
        searchByLatLon()
        collectionView.reloadData()
    }
    
    @objc func RetrieveNewCollection(sender:UIButton!) {
        for object in photoFetchedResultsController.fetchedObjects!{
            dataController.viewContext.delete(object)
        }
        try! dataController.viewContext.save()
        downloadImages()
    }
}





