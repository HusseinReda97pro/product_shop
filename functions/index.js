const functions = require('firebase-functions');
const cors = require('cors')({ orgin: true });
const Busboy = require('busboy');
const os = require('os');
const path = require('path');
const fs = require('fs'); // for file system
const fbAdmin = require('firebase-admin');
const uuid = require('uuid/v4');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// configration for google cloud functions to use firebase storage
const gcconfig = {
    projectId: 'flutterapp-5341d',
    keyFilename: 'flutter-products.json'
};

const gcs = require('@google-cloud/storage')(gcconfig);

fbAdmin.initializeApp({
    credential: fbAdmin.credential.cert(require('./flutter-products.json'))
});

exports.storeImage = functions.https.onRequest((req, res) => {
    return cors(req, res, () => {
        if (req.method !== 'POST') {
            return res.status(500).json({ 'message': 'Not Allowd' });
        }
        // if (!req.headers.authorization ||
        //     !req.headers.authorization.startsWith('Bearer ')) {
        //     return res.status(401).json({ error: 'Unauthorized.' });
        // }
        let idToken;
        idToken = req.headers.authorization.split('Bearer ')[1];
        // busboy pakage for extracting encoming files
        // return res.status(404).json({'message':req.headers});
        const busboy = new Busboy({ headers: req.headers });
        //  .on listin for event 
        let uploadData;
        let oldImagePath;
        // for upload image for first time
        busboy.on('file', (fieldname, file, filename, encoding, mimetype) => {
            const filepath = path.join(os.tmpdir(), filename);
            // tmpidr for get timporary file path on server
            uploadData = { filepath: filepath, type: mimetype, name: filename };
            // pipe for execute action on this file
            file.pipe(fs.createWriteStream(filepath));
        });
        // for update exist image
        busboy.on('field', (fieldname, value) => {
            oldImagePath = decodeURIComponent(value);
        });
        // for store
        busboy.on('finish', () => {
            const bucket = gcs.bucket('flutterapp-5341d.appspot.com');
            id = uuid();
            let imagePath = 'images/' + id + '-' + uploadData.name;
            if (oldImagePath) {
                imagePath = oldImagePath;
            }

            
            return fbAdmin
            .auth()
            .verifyIdToken(idToken)
            .then(decodedToken => {
                return bucket.upload(uploadData.filepath,{
                    uploadType: 'media',
                    destination:imagePath,
                    metaData:{
                        metaData:{
                            contentType:uploadData.type,
                            firebaseStorageDownloadTokens:id
                            
                        }
                    }
                   
                }).then(()=>{
                    return res.status(201).json({
                        imageUrl:
                        'https://firebasestorage.googleapis.com/v0/b/'+
                        bucket.name +
                        '/o/' +
                        encodeURIComponent(imagePath) + 
                        '?alt=media&token='+
                        id,
                        imagePath:imagePath
                    });
                });
            })
            .catch(error => {
                return res.status(401).json({ error: 'Unauthorized.' });
            }); 
        });
        return busboy.end(req.rawBody);
    });
});

exports.deleteImage = functions.database
    .ref('/products/{productId}')
    .onDelete(snapshot =>{
        const imageData = snapshot.val();
        const imagePath = imageData.imagePath;
        
        const bucket = gcs.bucket('flutterapp-5341d.appspot.com');
        return bucket.file(imagePath).delete();
    });