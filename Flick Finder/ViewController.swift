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
        
        guard searchTermTextField.text != "" else {
            flickLabel.text = "You must enter a search term"
            return
        }
        
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
        
        /* GUARD: Do both the search fields have values in them? */
        guard (!latTextField.text!.isEmpty || !longTextField.text!.isEmpty) else {
            flickLabel.text = "Enter a valid lat/long value.\nLat -90,90 and long -180,180"
            return
        }
        
        /* GUARD: Does the lat field have a vaule in it? */
        guard !latTextField.text!.isEmpty else {
            flickLabel.text = "Enter a valid lat value"
            return
        }
        
        /* GUARD: Does the long field have a value in it? */
        guard !longTextField.text!.isEmpty else {
            flickLabel.text = "Enter a valid long value"
            return
        }
        
        /* GUARD: Does the lat field have a valid value in it? */
        guard validateLatitude() else {
            flickLabel.text = "Enter a valid latitude; -90,90"
            return
        }
        
        /* GUARD: Does the long field have a valid value in it? */
        guard validateLongitude() else {
            flickLabel.text = "Enter a valid longitude; -180.180"
            return
        }
    
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
    
    ///Function to validate latitude
    func validateLatitude() -> Bool {
        if let latitude : Double? = Double(latTextField.text!) {
            if latitude < latMin || latitude > latMax {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    ///Function to validate longitude
    func validateLongitude() -> Bool {
        if let longitude : Double? = Double(longTextField.text!) {
            if longitude < lonMin || longitude > lonMax {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
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
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("Something happened: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print ("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print ("Your request returned an invalid response! Response: \(response)")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            //Parse the returned JSON into a Foundation object
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: \(parsedResult)")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "pages" key in photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
        }
        
        task.resume()
    }
    
    ///Method retrives a image from Flickr from a random page
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        /* Add the page to the method arguments*/
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = baseURL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
        
            //If there have been photos returned...
            if totalPhotosVal > 0 {
                //...make an array of all the dictionaries that hold information about photos
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'total' in \(photosDictionary)")
                    return
                }
                
                //Get a random index and pick a random photo dictionary
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                
                //Get the name of the image from the url
                var imageTitle = photoDictionary["title"] as? String
                
                if imageTitle == "" {
                    imageTitle = "This image has no title"
                }
                
                guard let imageUrl = photoDictionary["url_m"] as? String else {
                    print("Cannot find key 'url_m' in \(photosDictionary)")
                    return
                }
                
                //Get the image from the URL
                let imageUrlAsUrl = NSURL(string: imageUrl)
                if let imageData = NSData(contentsOfURL: imageUrlAsUrl!) {
                    
                    //Use the imageUrl to update the flickImageView and update the rest of the UI
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                        self.instructionalText.hidden = true
                        self.flickImageView.image = UIImage(data: imageData)
                        self.flickLabel.text = imageTitle
                    })
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

