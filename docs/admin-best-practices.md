# Best Practices

This page provides a summary of recommended best practices for managing your own deployment of VIAME-Web in the NOAA Fisheries Cloud. Note that these best practices should be evaluated and only used if appropriate to your specific use case.

## Staying up to date

Updating is very important

## Storing imagery

Within GCP, storage on Compute Engine disks is much more expensive than storage in [GCS buckets](https://cloud.google.com/storage/docs/introduction). Thus, it is recommended to store your imagery in a GCS bucket and mirror that bucket in your VIAME-Web deployment as a read-only assetstore. See [Cloud Storage Integration](admin-storage.md).
