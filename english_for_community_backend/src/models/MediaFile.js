const { Schema, model } = require('mongoose');

const MediaFileSchema = new Schema(
  {
    filename: { type: String, required: true },
    originalName: String,
    mimeType: String,
    size: Number,
    url: { type: String, required: true },
    purpose: String,
  },
  { timestamps: true }
);
let MediaFile = model('MediaFile', MediaFileSchema);
export default MediaFile;