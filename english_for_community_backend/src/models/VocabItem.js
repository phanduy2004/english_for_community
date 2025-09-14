const { Schema, model, Types } = require('mongoose');

const VocabItemSchema = new Schema(
  {
    setId: { type: Types.ObjectId, ref: 'VocabSet', required: true },
    term: { type: String, required: true },
    definition: { type: String, required: true },
    example: String,
    imageUrl: String,
    audioUrl: String,
  },
  { timestamps: true }
);

module.exports = model('VocabItem', VocabItemSchema);