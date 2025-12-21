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
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[ImageUploader] DEV_MODE: Returning mock image URL');
    return {
      imageUrl: DEV_MOCK_IMAGE_URL,
      publicId: 'logictales/dev-mock',
    };
  }

  console.log('[ImageUploader] Uploading to Cloudinary...');
  console.log(`[ImageUploader] Image data length: ${base64Image.length} chars`);

  // Check cloudinary config
  if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
    console.error('[ImageUploader] Missing Cloudinary credentials!');
    console.error(`[ImageUploader] CLOUD_NAME: ${process.env.CLOUDINARY_CLOUD_NAME ? 'set' : 'MISSING'}`);
    console.error(`[ImageUploader] API_KEY: ${process.env.CLOUDINARY_API_KEY ? 'set' : 'MISSING'}`);
    console.error(`[ImageUploader] API_SECRET: ${process.env.CLOUDINARY_API_SECRET ? 'set' : 'MISSING'}`);
    throw new Error('Cloudinary credentials not configured!');
  }

  const startTime = Date.now();

  let uploadResult;
  try {
    uploadResult = await cloudinary.uploader.upload(
      `data:image/png;base64,${base64Image}`,
      {
        upload_preset: 'ml_default',
        folder: 'logictales',
      }
    );
  } catch (err) {
    console.error('[ImageUploader] Cloudinary upload failed!');
    console.error('[ImageUploader] Error:', err instanceof Error ? err.message : err);
    if (err && typeof err === 'object' && 'http_code' in err) {
      console.error('[ImageUploader] HTTP Code:', (err as { http_code: number }).http_code);
    }
    throw new Error(`Cloudinary upload error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const durationMs = Date.now() - startTime;

  console.log(`[ImageUploader] Success! Completed in ${durationMs}ms`);
  console.log(`[ImageUploader] URL: ${uploadResult.secure_url}`);
  console.log(`[ImageUploader] Public ID: ${uploadResult.public_id}`);

  return {
    imageUrl: uploadResult.secure_url,
    publicId: uploadResult.public_id,
  };
}
