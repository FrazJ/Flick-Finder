//
//  ViewController.swift
//  Flick Finder
//
//  Created by Frazer Hogg on 22/09/2015.
//  Copyright © 2015 HomeProjects. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    let baseURL = "https://api.flickr.com/services/rest/"
    let methodName = "flickr.photos.search"
    let APIKey = "2a3d64b187e696bbf6c1d2a763fcaa65"
    let extras = "url_m"
    let safeSearch = "1"
    let dataFormat = "json"
    let noJSONCallback = "1"
    let boundingBoxHalfWidth = 1.0
    let boundingBoxHalfHeight = 1.0
    let latMin = -90.0
    let latMax = 90.0
    let lonMin = -180.0
    let lonMax = 180.0
    
    var tapRecogniser : UITapGestureRecognizer?
    
    // MARK: Outlets
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var flickLabel: UILabel!
    @IBOutlet weak var instructionalText: UILabel!
    @IBOutlet weak var searchTermTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var longTextField: UITextField!
    
    
    // MARK: View lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the delegates of the textFields to be this ViewController
        searchTermTextField.delegate = self
        latTextField.delegate = self
        longTextField.delegate = self
        
        //Create and configure a tapGestureRecogniser
        tapRecogniser = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecogniser?.numberOfTapsRequired = 1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardDismissRecogniser()
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardDismissRecogniser()
        unsubscribeFromKeyboardNotifications()
        
    }
    
    // MARK: Actions
    
    @IBAction func searchPhotosByPhraseButton(sender: UIButton) {
        
        //API method arguments
        let methodArguments = [
            "method" : methodName,
            "api_key" : APIKey,
            "text" : searchTermTextField.text!,
            "extras" : extras,
            "safe_search" : safeSearch,
            "format" : dataFormat,
            "nojsoncallback" : noJSONCallback
        ]
        
        getImageFromFlickr(methodArguments)
    }
 
    @IBAction func searchPhotosByLatLonButton(sender: UIButton) {
        
        //API method arguments
        let methodArguments = [
            "method" : methodName,
            "api_key" : APIKey,
            "bbox" : createBoundingBoxAttribue(),
            "extras" : extras,
            "safe_search" : safeSearch,
            "format" : dataFormat,
            "nojsoncallback" : noJSONCallback
        ]
        
        getImageFromFlickr(methodArguments)
        
    }
    
    
    //MARK: Functions
    
    ///Function retrives a image from Flickr
    func getImageFromFlickr(methodArguments: [String: AnyObject]) {
        
        //Get the chared NSURLSession to facilitate network activity
        let session = NSURLSession.sharedSession()
        
        //Create the NSURLRequest using escaped URL
        let urlString = baseURL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        //Initialise task for getting data and cimpletion handler: Completion hanlders happen in the background thread
        let task = session .dataTaskWithRequest(request) {(data, response, error) in
            
            /* COMPLETION BLOCK */
            /* Check for a successful response */
            
            //GAURD: Was there an error?
            guard (error == nil) else {
                print("Something happened \(error)")
                return
            }
            
            //Parse the returned JSON into a Foundation object
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            } catch {
                print("Couldn't parse the data")
                return
            }
            
            print(parsedResult)
            
            //Get the photos dictionary from Foundation object; this is all the photos.
            if let photosDictionary = parsedResult["photos"] as? [String:AnyObject] {
                
                //Determine the total number of photos in the photo dictionary
                var totalPhotosVal = 0
                if let totalPhotos = photosDictionary["total"] as? String {
                    totalPhotosVal = (totalPhotos as NSString).integerValue
                    print("total photos \(totalPhotosVal)")
                }
                
                //If there have been photos returned...
                if totalPhotosVal > 0 {
                    //...make an array of all the dictionaries that hold information about photos
                    if let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                        
                        //Get a random index and pick a random photo dictionary
                        let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                        let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                        
                        let imageUrl = photoDictionary["url_m"] as? String
                        
                        print(imageUrl)
                        
                        //Get the image from the URL
                        let imageUrlAsUrl = NSURL(string: imageUrl!)
                        let imageData = NSData(contentsOfURL: imageUrlAsUrl!)
                        let imageToDisplay = UIImage(data: imageData!)
                        
                        //Get the name of the image from the url
                        var imageTitle = photoDictionary["title"] as? String
                        
                        if imageTitle == "" {
                            imageTitle = "This image has no title"
                        }
                        
                        
                        //Use the imageUrl to update the flickImageView and update the rest of the UI
                        dispatch_async(dispatch_get_main_queue(), {() -> Void in
                            self.instructionalText.hidden = true
                            self.flickImageView.image = imageToDisplay
                            self.flickLabel.text = imageTitle
                        })
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                        self.instructionalText.hidden = false
                        self.flickImageView.image = nil
                        self.flickLabel.text = "No photos returned by Flickr"
                    })
                }
            }
            
        }
        task.resume()
    }
    
    ///Function that takes a string and makes it URL safe
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            //Ensure that the value is a String
            let stringValue = "\(value)"
            //Escape the value to ensure it will work in a URL
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            //Add the value to the URL var
            urlVars += [key + "=" + "\(escapedValue!)"]
            
            print(urlVars)
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    
    ///Function subscribes to keyboard notifications
    func subscribeToKeyboardNotifications() {
        
        //Subscirbe to be notified when the keyboard will be displayed
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        //Subscribe to be notifed when the keyboard will be hidden
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillHide:",
            name:UIKeyboardWillHideNotification,
            object: nil)
    }
    
    ///Function unsubscribes to keyboard notifications
    func unsubscribeFromKeyboardNotifications() {
        
        //Unsubscribe from receiving further notifications about when the keyboard will be shown
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        //Unsubscribe from receiving further notifications about then the keyboard will be hidden
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    ///Function get the height of the keyboard
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo! [UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    ///Function that moves the view up when a text field becomes active
    func keyboardWillShow(notification: NSNotification) {
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    ///Function that moves the view down when a text field becomes inactive
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    ///Function that adds a GestureRecogniser to the view
    func addKeyboardDismissRecogniser() {
        view.addGestureRecognizer(tapRecogniser!)
    }
    
    ///Function that remove a GestureRecogniser from the view
    func removeKeyboardDismissRecogniser() {
        view.removeGestureRecognizer(tapRecogniser!)
    }
    
    ///Function that ends editing in a text field when the user taps
    func handleSingleTap(recogniser: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    ///Function that creates the bounding box for the lat and long of a location
    func createBoundingBoxAttribue() -> String {
        
        let latitude = (latTextField.text! as NSString).doubleValue
        let longitude = (longTextField.text! as NSString).doubleValue
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottomLeftLon = max(longitude - boundingBoxHalfWidth, lonMin)
        let bottomLeftLat = max(latitude - boundingBoxHalfHeight, latMin)
        let topRightLon = min(longitude + boundingBoxHalfHeight, lonMax)
        let topRightLat = min(latitude + boundingBoxHalfHeight, latMax)
        
        return "\(bottomLeftLon),\(bottomLeftLat),\(topRightLon),\(topRightLat)"
        
    }
    
    // MARK: UITextFieldDelegate functions
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
}

