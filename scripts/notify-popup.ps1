# Detached helper for notify.ps1: plays the sound and shows a light card popup.
param([string]$Payload)
try {
    $data = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Payload)) | ConvertFrom-Json

    $played = $false
    if ($data.sound -and (Test-Path -LiteralPath $data.sound)) {
        try {
            if ([IO.Path]::GetExtension($data.sound) -eq '.wav') {
                $player = New-Object System.Media.SoundPlayer $data.sound
                $player.Play()
            } else {
                $player = New-Object -ComObject WMPlayer.OCX
                $player.URL = $data.sound
                $player.controls.play()
            }
            $played = $true
        } catch {}
    }
    if (-not $played) { [System.Media.SystemSounds]::Exclamation.Play() }

    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    # Borderless form with a native drop shadow (CS_DROPSHADOW), plus crisp text on high-DPI screens.
    Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System.Windows.Forms;
using System.Runtime.InteropServices;
public class CardForm : Form {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    protected override CreateParams CreateParams {
        get { var cp = base.CreateParams; cp.ClassStyle |= 0x20000; return cp; }
    }
}
"@
    [CardForm]::SetProcessDPIAware() | Out-Null
    [Windows.Forms.Application]::EnableVisualStyles()

    $accent = if ($data.event -eq 'Notification') { '#F59E0B' } else { '#22C55E' }
    $accent = [Drawing.ColorTranslator]::FromHtml($accent)
    $ink    = [Drawing.ColorTranslator]::FromHtml('#111827')
    $muted  = [Drawing.ColorTranslator]::FromHtml('#6B7280')
    $line   = [Drawing.ColorTranslator]::FromHtml('#E5E7EB')

    $form = New-Object CardForm
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.BackColor = [Drawing.Color]::White
    $form.KeyPreview = $true

    $g = $form.CreateGraphics(); $s = $g.DpiX / 96; $g.Dispose()
    $pad = [int](22 * $s); $width = [int](380 * $s)

    $title = New-Object Windows.Forms.Label
    $title.Text = 'Claude Code'
    $title.Font = New-Object Drawing.Font('Segoe UI Semibold', 9.5)
    $title.ForeColor = $muted
    $title.AutoSize = $true
    $title.Location = New-Object Drawing.Point(($pad + [int](16 * $s)), $pad)

    $close = New-Object Windows.Forms.Label
    $close.Text = [char]0x2715
    $close.Font = New-Object Drawing.Font('Segoe UI', 10)
    $close.ForeColor = $muted
    $close.AutoSize = $true
    $close.Cursor = 'Hand'
    $close.Location = New-Object Drawing.Point(($width - $pad - [int](12 * $s)), ($pad - [int](2 * $s)))
    $close.Add_MouseEnter({ $close.ForeColor = $ink })
    $close.Add_MouseLeave({ $close.ForeColor = $muted })

    $msg = New-Object Windows.Forms.Label
    $msg.Text = $data.message
    $msg.Font = New-Object Drawing.Font('Malgun Gothic', 13, [Drawing.FontStyle]::Bold)
    $msg.ForeColor = $ink
    $msg.AutoSize = $true
    $msg.MaximumSize = New-Object Drawing.Size(($width - 2 * $pad), 0)
    $msg.Location = New-Object Drawing.Point($pad, ($pad + [int](30 * $s)))
    $form.Controls.AddRange(@($title, $close, $msg))

    $bottom = $msg.Bottom
    if ($data.detail) {
        $det = New-Object Windows.Forms.Label
        $det.Text = $data.detail
        $det.Font = New-Object Drawing.Font('Malgun Gothic', 9.5)
        $det.ForeColor = $muted
        $det.AutoSize = $true
        $det.MaximumSize = New-Object Drawing.Size(($width - 2 * $pad), 0)
        $det.Location = New-Object Drawing.Point($pad, ($bottom + [int](8 * $s)))
        $form.Controls.Add($det)
        $bottom = $det.Bottom
    }
    $form.ClientSize = New-Object Drawing.Size($width, ($bottom + $pad))

    # Rounded corners
    $r = [int](14 * $s)
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $w = $form.ClientSize.Width; $h = $form.ClientSize.Height
    $path.AddArc(0, 0, $r * 2, $r * 2, 180, 90)
    $path.AddArc($w - $r * 2, 0, $r * 2, $r * 2, 270, 90)
    $path.AddArc($w - $r * 2, $h - $r * 2, $r * 2, $r * 2, 0, 90)
    $path.AddArc(0, $h - $r * 2, $r * 2, $r * 2, 90, 90)
    $path.CloseFigure()
    $form.Region = New-Object Drawing.Region($path)

    $form.Add_Paint({
        param($sender, $e)
        $e.Graphics.SmoothingMode = 'AntiAlias'
        $pen = New-Object Drawing.Pen($line, [Math]::Max(1, $s))
        $e.Graphics.DrawPath($pen, $path)
        $d = [int](9 * $s)
        $dotY = $title.Top + [int](($title.Height - $d) / 2)
        $brush = New-Object Drawing.SolidBrush($accent)
        $e.Graphics.FillEllipse($brush, $pad, $dotY, $d, $d)
        $pen.Dispose(); $brush.Dispose()
    })

    # Close on ✕, clicking the card, or Esc/Enter
    $close.Add_Click({ $form.Close() })
    $form.Add_Click({ $form.Close() })
    foreach ($c in @($title, $msg) + @($form.Controls | Where-Object { $_ -ne $close })) { $c.Add_Click({ $form.Close() }) }
    $form.Add_KeyDown({ if ($_.KeyCode -in 'Escape', 'Enter') { $form.Close() } })

    [void]$form.ShowDialog()
} catch {}
