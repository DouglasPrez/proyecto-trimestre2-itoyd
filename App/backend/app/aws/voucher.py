from datetime import datetime


def build_voucher_html(
    reservation_code: str,
    space_name: str,
    complex_name: str,
    sport_type: str,
    start_time: datetime,
    end_time: datetime,
    amount_paid: float,
    payment_last4: str,
    user_email: str,
) -> str:
    date_str = start_time.strftime("%A %d de %B de %Y").capitalize()
    time_str = f"{start_time.strftime('%H:%M')} – {end_time.strftime('%H:%M')}"
    generated = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Comprobante {reservation_code} — SportSpace</title>
  <style>
    body {{
      font-family: 'Segoe UI', Arial, sans-serif;
      background: #f4f6fb;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      padding: 40px 16px;
      margin: 0;
      color: #1a1a2e;
    }}
    .card {{
      background: #fff;
      border-radius: 16px;
      box-shadow: 0 4px 24px rgba(0,0,0,.10);
      max-width: 480px;
      width: 100%;
      padding: 36px 32px;
    }}
    .header {{
      text-align: center;
      margin-bottom: 28px;
    }}
    .check {{
      font-size: 48px;
      line-height: 1;
    }}
    h1 {{
      color: #16a34a;
      font-size: 1.5rem;
      margin: 8px 0 4px;
    }}
    .code {{
      font-family: monospace;
      font-size: 1.1rem;
      background: #eff6ff;
      color: #1d4ed8;
      border-radius: 8px;
      padding: 6px 14px;
      display: inline-block;
      letter-spacing: 1px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }}
    td {{
      padding: 10px 0;
      border-bottom: 1px solid #f0f0f0;
      font-size: .95rem;
    }}
    td:first-child {{
      color: #6b7280;
      width: 40%;
    }}
    td:last-child {{
      font-weight: 500;
      text-align: right;
    }}
    .total td {{
      border-bottom: none;
      font-size: 1.05rem;
      font-weight: 700;
    }}
    .total td:last-child {{
      color: #1d4ed8;
    }}
    .footer {{
      text-align: center;
      font-size: .8rem;
      color: #9ca3af;
      margin-top: 24px;
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="check">✓</div>
      <h1>Reserva confirmada</h1>
      <div class="code">{reservation_code}</div>
    </div>
    <table>
      <tr><td>Complejo</td><td>{complex_name}</td></tr>
      <tr><td>Espacio</td><td>{space_name}</td></tr>
      <tr><td>Deporte</td><td>{sport_type}</td></tr>
      <tr><td>Fecha</td><td>{date_str}</td></tr>
      <tr><td>Horario</td><td>{time_str}</td></tr>
      <tr><td>Tarjeta</td><td>**** **** **** {payment_last4}</td></tr>
      <tr class="total"><td>Total pagado</td><td>Q{amount_paid:.2f}</td></tr>
    </table>
    <p style="text-align:center;font-size:.85rem;color:#6b7280;">
      Confirmación enviada a: {user_email}
    </p>
    <div class="footer">Generado {generated} · SportSpace</div>
  </div>
</body>
</html>"""
