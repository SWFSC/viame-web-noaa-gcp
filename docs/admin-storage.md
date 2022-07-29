# Cloud Storage Integration

This guide details how to store your imagery in a GCS bucket and mirror that that to your VIAME-Web deployment. This will allow all users to see and use (e.g., annotate, run models on) imagery in the bucket, while ensuring that users cannot delete or modify imagery in the bucket. Annotations are stored in a MongoDB database on the VM.

## Setup

This section expands on the [Cloud Storage Integration docs](https://kitware.github.io/dive/Deployment-Storage).

### Creating access credentials

Follow the [Creating access credentials instructions](https://kitware.github.io/dive/Deployment-Storage/#creating-access-credentials). You should already have created the service account during [deployment](deployment-general.md#create-gcp-resources). You must create an access key for the same service account that is attached to your VM(s).

### Setting up CORS

Confirm that [CORS headers are configured](https://kitware.github.io/dive/Deployment-Storage/#setting-up-cors) for your GCS bucket(s).

### Create Assetstore

Go to <http://localhost:8010/girder#assetstores>, and click ‘Create new Amazon S3 assetstore’. Fill in the options as follows:

* Assetstore name: The name of the assetstore. It is recommended to use the same name as the bucket.
* S3 bucket name The name of the GCS bucket.
* Path prefix (optional): Leave this blank if you wish to mount the whole bucket.
* Access key ID: The access key ID from creating your service account access credentials.
* Secret access key: The secret key from creating your service account access credentials.
* Service: Enter the GCP service url: `https://storage.googleapis.com`.
* Region: The GCP region that your bucket is in. This will likely be `us-east4`.
* It is recommended that you check 'Read only' so that users cannot edit the bucket through the VIAME-Web deployment.

Click the 'Create' button to create the assetstore.

### Create local mount point

To make these data broadly accessible to the users of your deployment, create a ‘Collection’. Go to ‘Collections’ tab on the Girder page (<http://localhost:8010/girder#collections>) and click ‘Create collection’. Make the collection name the same as the bucket. Create a folder within the collection called 'bucket-mount’. Get the ‘Unique ID’ of the 'bucket-mount' folder by clicking into the folder and clicking the ‘I’ (info) button. Copy this unique ID.

For users to be able to annotate images from the mounted bucket, you must give them edit permissions on the collection. To give a user permission to annotate any images in the collection: 

1. Click into the collection, click 'Actions', and select 'Access control'. 
1. Add users as editors as appropriate and select 'Also set permissions on all subfolders to match this collection's permissions'. 
1. Click 'Save'.

You can also specify more granular levels of permissions as appropriate.

### Import data

Now that the mount point has been created, you must 'import' the data from the bucket. Go back to <http://localhost:8010/girder#assetstores> and click 'Import data' for the desired assetstore. Enter the unique ID of the 'bucket-mount' folder in the 'Destination ID' box. If you wish to import the whole bucket, leave 'Import path' blank. Click 'Begin import' and the service will begin to import the data so that the imagery and folders in the bucket show up in the collection.

## Assetstore Management

See [these docs] (https://kitware.github.io/dive/Deployment-Storage/#s3-and-minio-mirroring) and [this question](https://kitware.github.io/dive/FAQ/#how-can-i-load-data-incrementally) for data mirroring guidelines. 

### Adding or deleting data

Whenever you add new folders and/or imagery to the bucket, you must repeat the 'Import data' step. Currently the mount point can only be kept up to date automatically using [Pub/Sub notifications](https://kitware.github.io/dive/Deployment-Storage/#pubsub-notifications) if your server has a public static IP address.

Also, without Pub/Sub notifications, you must delete folders from the collection using the VIAME-Web user interface, even after deleting the folders from the bucket. 
