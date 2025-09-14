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

module.exports = model('MediaFile', MediaFileSchema);