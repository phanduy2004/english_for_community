import mongoose from "mongoose";


const UnitSchema = new mongoose.Schema(
  {
    trackId: { type: mongoose.Schema.Types.ObjectId, ref: 'Track', required: true },
    name: { type: String, required: true },
    description: String,
    order: { type: Number, default: 0 },
    imageUrl: String,
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);
let Unit = mongoose.model('Unit', UnitSchema)
export default Unit;