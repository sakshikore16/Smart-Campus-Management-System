const multer = require('multer');
const path = require('path');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowed = /\.(pdf|doc|docx|jpg|jpeg|png|gif|webp|bmp|tiff|heic|txt|csv|xls|xlsx)$/i;
  if (allowed.test(path.extname(file.originalname))) {
    cb(null, true);
  } else {
    cb(new Error('Allowed: PDF, DOC, DOCX, JPG, PNG, GIF, WEBP, BMP, TIFF, HEIC, TXT, CSV, XLS, XLSX.'), false);
  }
};

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});

module.exports = upload;
