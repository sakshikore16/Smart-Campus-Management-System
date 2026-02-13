require("dotenv").config();
const express = require("express");
const cors = require("cors");
const connectDB = require("./config/db");
const { ensureDefaultAdmin } = require("./scripts/ensureDefaultAdmin");

const authRoutes = require("./routes/auth");
const adminRoutes = require("./routes/admin");
const userRoutes = require("./routes/users");
const attendanceRoutes = require("./routes/attendance");
const leaveRoutes = require("./routes/leaves");
const noticeRoutes = require("./routes/notices");
const notificationRoutes = require("./routes/notifications");
const fileRoutes = require("./routes/files");
const complaintRoutes = require("./routes/complaints");
const expenseRoutes = require("./routes/expenses");
const timetableRoutes = require("./routes/timetable");
const statsRoutes = require("./routes/stats");
const grievanceRoutes = require("./routes/grievances");
const feePaymentRoutes = require("./routes/feePayments");
const feeReceiptRequestRoutes = require("./routes/feeReceiptRequests");
const marksRoutes = require("./routes/marks");
const idCardRequestRoutes = require("./routes/idCardRequests");
const budgetRoutes = require("./routes/budgets");
const meetingRoutes = require("./routes/meetings");

const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/users", userRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/leaves", leaveRoutes);
app.use("/api/notices", noticeRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/files", fileRoutes);
app.use("/api/complaints", complaintRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/timetable", timetableRoutes);
app.use("/api/stats", statsRoutes);
app.use("/api/grievances", grievanceRoutes);
app.use("/api/fee-payments", feePaymentRoutes);
app.use("/api/fee-receipt-requests", feeReceiptRequestRoutes);
app.use("/api/marks", marksRoutes);
app.use("/api/id-card-requests", idCardRequestRoutes);
app.use("/api/budgets", budgetRoutes);
app.use("/api/meetings", meetingRoutes);

app.get("/api/health", (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 5001;
(async () => {
  try {
    await connectDB();
    await ensureDefaultAdmin();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  } catch (err) {
    console.error('Server startup error:', err);
    process.exit(1);
  }
})();
