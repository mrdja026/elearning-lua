import { v2 as cloudinary } from 'cloudinary';

const DEV_MOCK_IMAGE_URL = 'https://res.cloudinary.com/dvzbmvrxs/image/upload/v1765646051/logictales/sormpv8m1skh5a18o6uf.png';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export interface ImageUploadResult {
  imageUrl: string;
  publicId: string;
}

export async function uploadImage(base64Image: string): Promise<ImageUploadResult> {
  // DEV_MODE: Return mock image URL to save API credits
  if (process.env.DEV_MODE === 'true') {
    console.log('[ImageUploader] DEV_MODE: Returning mock image URL');
    return {
      imageUrl: DEV_MOCK_IMAGE_URL,
      publicId: 'logictales/dev-mock',
    };
  }

  console.log('[ImageUploader] Uploading to Cloudinary...');

  const startTime = Date.now();

  const uploadResult = await cloudinary.uploader.upload(
    `data:image/png;base64,${base64Image}`,
    {
      upload_preset: 'ml_default',
      folder: 'logictales',
    }
  );

  const durationMs = Date.now() - startTime;

  console.log(`[ImageUploader] Completed in ${durationMs}ms`);
  console.log(`[ImageUploader] URL: ${uploadResult.secure_url}`);

  return {
    imageUrl: uploadResult.secure_url,
    publicId: uploadResult.public_id,
  };
}
