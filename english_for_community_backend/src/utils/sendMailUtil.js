import nodemailer from 'nodemailer'

const {
  SMTP_HOST,
  SMTP_PORT,
  SMTP_SECURE,
  SMTP_USER,
  SMTP_PASS,
  SMTP_FROM_EMAIL,
  SMTP_FROM_NAME
} = process.env

// Tạo transporter 1 lần
const transporter = nodemailer.createTransport({
  host: SMTP_HOST || 'smtp.gmail.com',
  port: Number(SMTP_PORT || 465),
  secure: String(SMTP_SECURE ?? 'true') === 'true', // 465 = true
  auth: {
    user: SMTP_USER,
    pass: SMTP_PASS
  }
})

// (không bắt buộc) verify kết nối lúc khởi động:
transporter.verify().then(() => {
  console.log('📧 SMTP connected and ready')
}).catch(err => {
  console.error('❌ SMTP verify failed:', err?.message || err)
})

export default async function sendMail(to, subject, text, html) {
  if (!to) throw new Error('Missing "to" email')
  const fromName = SMTP_FROM_NAME || 'E4C'
  const fromEmail = SMTP_FROM_EMAIL || SMTP_USER

  const info = await transporter.sendMail({
    from: `"${fromName}" <${fromEmail}>`,
    to,
    subject,
    text: text || undefined,
    html: html || undefined
  })
  return info
}
