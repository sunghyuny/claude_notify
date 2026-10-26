# Detached helper for notify.ps1: plays the sound and shows a light card popup.
param([string]$Payload)

# ===== Design settings: edit these to change how the card looks =====
$Design = @{
    Width             = 380            # card width (px at 100% scaling)
    Padding           = 22             # inner margin
    CornerRadius      = 14
    Position          = 'Center'       # Center | TopCenter | BottomRight
    AutoCloseSeconds  = 0              # 0 = stay until closed
    Title             = 'Claude Code'
    Background        = '#FFFFFF'
    TextColor         = '#111827'
    SubTextColor      = '#6B7280'
    BorderColor       = '#E5E7EB'
    StopColor         = '#22C55E'      # dot color: response finished
    NotificationColor = '#F59E0B'      # dot color: waiting for approval/input
    TitleFont         = 'Segoe UI Semibold'
    TitleSize         = 9.5
    MessageFont       = 'Malgun Gothic'
    MessageSize       = 13
    DetailSize        = 9.5
}
# =====================================================================

try {
    $data = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Payload)) | ConvertFrom-Json

    # Turns a link into a local file, downloading it once into the cache folder.
    # Accepts a direct audio link (.mp3/.wav) or a web page such as a myinstants.com sound page,
    # in which case the page's og:audio tag (or its first audio link) is used.
    function Get-CachedSound([string]$url, [string]$cacheDir) {
        $sha = [Security.Cryptography.SHA1]::Create()
        $hash = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($url)) | ForEach-Object { $_.ToString('x2') })
        $cached = Get-ChildItem -LiteralPath $cacheDir -Filter "$hash.*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cached) { return $cached.FullName }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        $audio = $url
        if ($url -notmatch '\.(mp3|wav)(\?|$)') {
            $html = (Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent $ua -TimeoutSec 15).Content
            if ($html -match '<meta[^>]+property="og:audio"[^>]+content="([^"]+)"') { $audio = $Matches[1] }
            elseif ($html -match '["'']([^"''\s]+\.(?:mp3|wav))["'']') { $audio = $Matches[1] }
            else { return $null }
            $audio = ([Uri]::new([Uri]$url, $audio)).AbsoluteUri
        }
        $ext = if ($audio -match '\.wav(\?|$)') { '.wav' } else { '.mp3' }
        New-Item -ItemType Directory -Force $cacheDir | Out-Null
        $target = Join-Path $cacheDir "$hash$ext"
        Invoke-WebRequest -Uri $audio -UseBasicParsing -UserAgent $ua -TimeoutSec 30 -OutFile "$target.part"
        Move-Item -Force "$target.part" $target
        return $target
    }

    $sound = $data.sound
    if ($sound -match '^https?://') {
        try { $sound = Get-CachedSound $sound $data.cache } catch { $sound = $null }
    }
    if (-not $sound -or -not (Test-Path -LiteralPath $sound)) { $sound = $data.fallback }

    $played = $false
    if ($sound -and (Test-Path -LiteralPath $sound)) {
        try {
            if ([IO.Path]::GetExtension($sound) -eq '.wav') {
                $player = New-Object System.Media.SoundPlayer $sound
                $player.Play()
            } else {
                $player = New-Object -ComObject WMPlayer.OCX
                $player.URL = $sound
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

    $accent = if ($data.event -eq 'Notification') { $Design.NotificationColor } else { $Design.StopColor }
    $accent = [Drawing.ColorTranslator]::FromHtml($accent)
    $ink    = [Drawing.ColorTranslator]::FromHtml($Design.TextColor)
    $muted  = [Drawing.ColorTranslator]::FromHtml($Design.SubTextColor)
    $line   = [Drawing.ColorTranslator]::FromHtml($Design.BorderColor)

    $form = New-Object CardForm
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.BackColor = [Drawing.ColorTranslator]::FromHtml($Design.Background)
    $form.KeyPreview = $true

    $g = $form.CreateGraphics(); $s = $g.DpiX / 96; $g.Dispose()
    $pad = [int]($Design.Padding * $s); $width = [int]($Design.Width * $s)

    $title = New-Object Windows.Forms.Label
    $title.Text = $Design.Title
    $title.Font = New-Object Drawing.Font($Design.TitleFont, $Design.TitleSize)
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
    $msg.Font = New-Object Drawing.Font($Design.MessageFont, $Design.MessageSize, [Drawing.FontStyle]::Bold)
    $msg.ForeColor = $ink
    $msg.AutoSize = $true
    $msg.MaximumSize = New-Object Drawing.Size(($width - 2 * $pad), 0)
    $msg.Location = New-Object Drawing.Point($pad, ($pad + [int](30 * $s)))
    $form.Controls.AddRange(@($title, $close, $msg))

    $bottom = $msg.Bottom
    if ($data.detail) {
        $det = New-Object Windows.Forms.Label
        $det.Text = $data.detail
        $det.Font = New-Object Drawing.Font($Design.MessageFont, $Design.DetailSize)
        $det.ForeColor = $muted
        $det.AutoSize = $true
        $det.MaximumSize = New-Object Drawing.Size(($width - 2 * $pad), 0)
        $det.Location = New-Object Drawing.Point($pad, ($bottom + [int](8 * $s)))
        $form.Controls.Add($det)
        $bottom = $det.Bottom
    }
    $form.ClientSize = New-Object Drawing.Size($width, ($bottom + $pad))

    $area = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $gap = [int](24 * $s)
    $x = $area.Left + [int](($area.Width - $form.Width) / 2)
    $y = switch ($Design.Position) {
        'TopCenter'   { $area.Top + $gap }
        'BottomRight' { $x = $area.Right - $form.Width - $gap; $area.Bottom - $form.Height - $gap }
        default       { $area.Top + [int](($area.Height - $form.Height) / 2) }
    }
    $form.Location = New-Object Drawing.Point($x, $y)

    # Rounded corners
    $r = [int]($Design.CornerRadius * $s)
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

    if ($Design.AutoCloseSeconds -gt 0) {
        $timer = New-Object Windows.Forms.Timer
        $timer.Interval = [int]($Design.AutoCloseSeconds * 1000)
        $timer.Add_Tick({ $timer.Stop(); $form.Close() })
        $timer.Start()
    }

    [void]$form.ShowDialog()
} catch {}
