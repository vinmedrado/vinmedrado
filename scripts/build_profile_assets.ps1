$ErrorActionPreference = 'Stop'

Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root 'assets'
$sourceDir = Join-Path $assets 'source'
$cardsDir = Join-Path $assets 'cards'

New-Item -ItemType Directory -Force -Path $sourceDir, $cardsDir | Out-Null

function Save-RemoteFile {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Path
    )

    Invoke-WebRequest -Uri $Url -Headers @{ 'User-Agent' = 'Codex' } -OutFile $Path | Out-Null
}

function Get-DataUri {
    param([Parameter(Mandatory = $true)][string]$Path)

    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    $bytes = if ($ext -eq '.svg') {
        [Text.Encoding]::UTF8.GetBytes((Get-Content -Raw -Encoding UTF8 $Path))
    } else {
        [IO.File]::ReadAllBytes($Path)
    }

    $mime = switch ($ext) {
        '.png' { 'image/png' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.svg' { 'image/svg+xml' }
        default { throw "Unsupported image type: $ext" }
    }

    return "data:$mime;base64,$([Convert]::ToBase64String($bytes))"
}

function Escape-Xml {
    param([Parameter(Mandatory = $true)][string]$Text)
    return [Security.SecurityElement]::Escape($Text)
}

function Build-CardSvg {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Subtitle,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string[]]$Tags,
        [Parameter(Mandatory = $true)][string]$Accent,
        [Parameter(Mandatory = $true)][string]$AccentSoft,
        [Parameter(Mandatory = $true)][string]$Header,
        [Parameter()][string]$ImageDataUri,
        [Parameter()][bool]$UseIllustration = $false
    )

    $titleEsc = Escape-Xml $Title
    $subtitleEsc = Escape-Xml $Subtitle
    $descriptionEsc = Escape-Xml $Description
    $headerEsc = Escape-Xml $Header

    $tagXml = ''
    $tagX = 72
    foreach ($tag in $Tags) {
        $tagText = Escape-Xml $tag
        $width = [Math]::Max(74, ($tag.Length * 11) + 28)
        $tagXml += @"
    <g>
      <rect x="$tagX" y="528" width="$width" height="38" rx="19" fill="#0b1220" stroke="$AccentSoft" stroke-width="1.5" opacity="0.95" />
      <text x="$([int]($tagX + ($width / 2)))" y="553" fill="#e2e8f0" text-anchor="middle" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="16" font-weight="700">$tagText</text>
    </g>
"@
        $tagX += $width + 12
    }

    $visualXml = if ($UseIllustration) {
@"
    <rect x="680" y="118" width="448" height="304" rx="28" fill="#020617" opacity="0.82" stroke="#1f2937" />
    <rect x="708" y="146" width="392" height="248" rx="22" fill="#0b1220" stroke="$AccentSoft" stroke-width="1.5" />
    <path d="M728 332C772 268 812 242 850 242C888 242 926 272 964 318C994 354 1032 356 1080 310" fill="none" stroke="$Accent" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" />
    <circle cx="782" cy="278" r="18" fill="$Accent" opacity="0.95" />
    <circle cx="878" cy="246" r="18" fill="$AccentSoft" opacity="0.95" />
    <circle cx="978" cy="312" r="18" fill="$Accent" opacity="0.95" />
    <circle cx="1064" cy="286" r="18" fill="$AccentSoft" opacity="0.95" />
    <text x="734" y="198" fill="#e2e8f0" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="18" font-weight="700">decision flow</text>
    <text x="734" y="224" fill="#94a3b8" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="15" font-weight="500">auditable, temporal and operational</text>
    <path d="M734 360H1066" stroke="#1f2937" stroke-width="1.5" />
    <path d="M734 372H1022" stroke="#1f2937" stroke-width="1.5" />
"@
    } else {
@"
    <rect x="660" y="104" width="480" height="328" rx="30" fill="#020617" opacity="0.78" stroke="#1f2937" />
    <rect x="686" y="130" width="428" height="276" rx="22" fill="#0b1220" stroke="$AccentSoft" stroke-width="1.5" />
    <image href="$ImageDataUri" x="702" y="146" width="396" height="244" preserveAspectRatio="xMidYMid meet" />
"@
    }

    return @"
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="675" viewBox="0 0 1200 675" role="img" aria-labelledby="title desc">
  <title id="title">$titleEsc</title>
  <desc id="desc">$descriptionEsc</desc>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#020617" />
      <stop offset="55%" stop-color="#0f172a" />
      <stop offset="100%" stop-color="$AccentSoft" />
    </linearGradient>
    <radialGradient id="glow" cx="70%" cy="25%" r="70%">
      <stop offset="0%" stop-color="$Accent" stop-opacity="0.24" />
      <stop offset="100%" stop-color="$Accent" stop-opacity="0" />
    </radialGradient>
  </defs>
  <rect width="1200" height="675" rx="32" fill="url(#bg)" />
  <circle cx="980" cy="104" r="180" fill="$Accent" opacity="0.16" />
  <circle cx="822" cy="374" r="250" fill="$AccentSoft" opacity="0.18" />
  <rect x="28" y="28" width="1144" height="619" rx="28" fill="none" stroke="#1f2937" stroke-width="2" />
  <rect x="52" y="52" width="1096" height="571" rx="24" fill="url(#glow)" />

  <text x="72" y="102" fill="#94a3b8" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="18" font-weight="700" letter-spacing="4">$headerEsc</text>
  <text x="72" y="188" fill="#ffffff" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="58" font-weight="800">$titleEsc</text>
  <text x="72" y="238" fill="#dbeafe" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="24" font-weight="600">$subtitleEsc</text>
  <text x="72" y="284" fill="#cbd5e1" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="18" font-weight="500">$descriptionEsc</text>

  <rect x="72" y="336" width="164" height="42" rx="21" fill="#0b1220" stroke="$AccentSoft" stroke-width="1.5" />
  <text x="154" y="363" fill="#f8fafc" text-anchor="middle" font-family="Segoe UI, Inter, Arial, sans-serif" font-size="18" font-weight="700">Featured work</text>

$visualXml
$tagXml
</svg>
"@
}

function Write-Card {
    param(
        [Parameter(Mandatory = $true)][string]$Slug,
        [Parameter(Mandatory = $true)][string]$Svg
    )

    $path = Join-Path $cardsDir "$Slug.svg"
    Set-Content -Path $path -Value $Svg -Encoding UTF8
}

Save-RemoteFile 'https://raw.githubusercontent.com/vinmedrado/marketplace-seller-platform/main/portfolio/public/linkedin-card.png' (Join-Path $sourceDir 'marketplace-linkedin-card.png')
Save-RemoteFile 'https://raw.githubusercontent.com/vinmedrado/applymize/main/docs/branding/applymize_brand_board.png' (Join-Path $sourceDir 'applymize-brand-board.png')
Save-RemoteFile 'https://raw.githubusercontent.com/vinmedrado/Lumyra/main/frontend_web/src/assets/branding/lumyra-brand-board.jpg' (Join-Path $sourceDir 'lumyra-brand-board.jpg')
Save-RemoteFile 'https://raw.githubusercontent.com/vinmedrado/vinance/main/frontend/src/assets/brand/vinance-logo-original.png' (Join-Path $sourceDir 'vinance-logo-original.png')
Save-RemoteFile 'https://raw.githubusercontent.com/vinmedrado/meu-carro-vale/main/frontend/public/brand/logo-meu-carro-vale.svg' (Join-Path $sourceDir 'meu-carro-vale-logo.svg')

$marketplace = Get-DataUri (Join-Path $sourceDir 'marketplace-linkedin-card.png')
$applymize = Get-DataUri (Join-Path $sourceDir 'applymize-brand-board.png')
$lumyra = Get-DataUri (Join-Path $sourceDir 'lumyra-brand-board.jpg')
$vinance = Get-DataUri (Join-Path $sourceDir 'vinance-logo-original.png')
$mcv = Get-DataUri (Join-Path $sourceDir 'meu-carro-vale-logo.svg')

Write-Card 'marketplace-seller-platform' (Build-CardSvg `
    -Title 'Marketplace Seller Platform' `
    -Subtitle 'Inteligencia comercial para vendedores' `
    -Description 'Precificacao, dados e ML em uma plataforma full-stack com foco em operacao.' `
    -Tags @('React', 'FastAPI', 'ML') `
    -Accent '#38bdf8' `
    -AccentSoft '#1d4ed8' `
    -Header '01 / 06' `
    -ImageDataUri $marketplace)

Write-Card 'applymize' (Build-CardSvg `
    -Title 'Applymize' `
    -Subtitle 'Carreira, vagas e automacao de ATS' `
    -Description 'Experiencia interativa para matching, pipeline e rotina de candidatura.' `
    -Tags @('Full-stack', 'Automation', 'ATS') `
    -Accent '#34d399' `
    -AccentSoft '#047857' `
    -Header '02 / 06' `
    -ImageDataUri $applymize)

Write-Card 'lumyra' (Build-CardSvg `
    -Title 'Lumyra' `
    -Subtitle 'Operacao moderna de eventos' `
    -Description 'Realtime, paineis e automacoes para uma operacao visual e confiavel.' `
    -Tags @('Realtime', 'TypeScript', 'Ops') `
    -Accent '#f472b6' `
    -AccentSoft '#7c3aed' `
    -Header '03 / 06' `
    -ImageDataUri $lumyra)

Write-Card 'football-decision-lab' (Build-CardSvg `
    -Title 'Football Decision Lab' `
    -Subtitle 'Decisao esportiva auditavel' `
    -Description 'ML temporal, MLOps e experimentacao responsavel para pesquisa aplicada.' `
    -Tags @('ML', 'MLOps', 'Research') `
    -Accent '#86efac' `
    -AccentSoft '#14532d' `
    -Header '04 / 06' `
    -UseIllustration $true)

Write-Card 'vinance' (Build-CardSvg `
    -Title 'Vinance' `
    -Subtitle 'Financas com IA' `
    -Description 'Orcamento, ERP e investimentos em um unico fluxo operacional.' `
    -Tags @('AI', 'Finance', 'Analytics') `
    -Accent '#c4b5fd' `
    -AccentSoft '#312e81' `
    -Header '05 / 06' `
    -ImageDataUri $vinance)

Write-Card 'meu-carro-vale' (Build-CardSvg `
    -Title 'Meu Carro Vale' `
    -Subtitle 'Valuation automotivo' `
    -Description 'Dados, busca inteligente e precificacao para avaliacao rapida.' `
    -Tags @('SaaS', 'Data', 'Pricing') `
    -Accent '#fde68a' `
    -AccentSoft '#b45309' `
    -Header '06 / 06' `
    -ImageDataUri $mcv)
