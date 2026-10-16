const mongoose = require('mongoose');

const ingresoSchema = new mongoose.Schema(
  {
    monto: {
      type: Number,
      required: [true, 'El monto es requerido.'],
      min: [0.01, 'El monto debe ser mayor a 0.'],
    },
    nombre: {
      type: String,
      trim: true,
      default: '',
    },
    descripcion: {
      type: String,
      required: [true, 'La descripción es requerida.'],
      trim: true,
    },
    fecha: {
      type: Date,
      required: [true, 'La fecha es requerida.'],
      default: Date.now,
    },
    tipo_registro: {
      type: String,
      required: true,
      enum: ['manual', 'ai_yape'],
      default: 'manual',
    },
  },
  {
    timestamps: true,
    collection: 'gastosclaros_ingresos',
  }
);

// Índice para consultas por fecha (filtros de tiempo)
ingresoSchema.index({ fecha: -1 });

module.exports = mongoose.models.Ingreso || mongoose.model('Ingreso', ingresoSchema);
