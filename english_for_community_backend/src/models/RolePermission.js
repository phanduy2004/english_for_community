import mongoose from 'mongoose';

const RolePermissionSchema = new mongoose.Schema(
  {
    role: { type: String, required: true, unique: true, index: true },
    permissions: [{ type: String }],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true, versionKey: false }
);

const RolePermission = mongoose.model('RolePermission', RolePermissionSchema, 'role_permissions');
export default RolePermission;
