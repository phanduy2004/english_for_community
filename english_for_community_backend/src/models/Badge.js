const { Schema, model } = require('mongoose');

const BadgeSchema = new Schema(
  {
    name: { type: String, required: true },
    description: String,
    imageUrl: String,
    criteria: Schema.Types.Mixed,
    category: String,
  },
  { timestamps: true }
);

module.exports = model('Badge', BadgeSchema);