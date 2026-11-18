# Ancient Shell

[English](README.md) | **Português (Brasil)**

Desktop shell em [Quickshell](https://quickshell.org) para Hyprland, no visual dos painéis da tecnologia anciã de Stargate: pedra carvão, luz ciano dos glifos e o âmbar/bronze dos consoles de Atlântida.

Ele substitui waybar, swaync, hyprpaper, waypaper, rofi e wlogout.

## O que tem

| Peça | Atalho | Notas |
|---|---|---|
| Splash de boot | — | Ao entrar na sessão, o Stargate disca enquanto o shell carrega. Quando o shell responde, o 7º chevron trava, o buraco de minhoca abre e a tela mergulha nele até o desktop. Ao conectar, sorteia o planeta de destino (Abydos, Chulak, Dakara, Atlântida…), mostra o nome na tela e manda uma notificação do sistema. Um clique pula a animação. Se o shell não responder em 90 s, mostra "FALHA NA DISCAGEM" e sai. |
| Barra | — | Número do workspace ativo (role o mouse sobre ele para trocar), janela ativa, o relógio, a mídia, a bandeja, as atualizações de pacotes e o status. |
| Dashboard | `SUPER+A` ou clique no relógio | Relógio, calendário, uptime/memória/disco e medidores em anel (CPU, MEM, TEMP, DISCO). |
| Player de mídia | clique no título da música na barra | Capa, faixa, progresso e controles do player MPRIS ativo. Na barra, o clique direito dá play/pause e o do meio pula a faixa. O botão "Efeitos" vira o player para os efeitos de música. |
| Efeitos de música | "Efeitos" no player | Enquanto o player toca, a área de trabalho reage à música, por baixo das janelas. Visualizador em seis formas (barras, onda, espelho, anel, halo com a capa do álbum, Annabelle) e partículas que voam do centro; letra sincronizada, com as palavras acendendo no ritmo; e o wallpaper com brilho, desfoque, zoom e tremor nas batidas. Um controle de intensidade (10–200%) vale para tudo. Detalhes abaixo. |
| Central de controle | `SUPER+N` ou clique no status; botão direito no Wi-Fi ou no Bluetooth abre o `nm-connection-editor` ou o `blueman-manager` (`networkSettingsCommand` e `bluetoothSettingsCommand` no config) | Wi-Fi, redes Wi-Fi conhecidas no alcance (perfis salvos no NetworkManager: clique para conectar ou desconectar, "Editar" abre o `nm-connection-editor`), Bluetooth (dispositivos conectados com bateria e botão de desconectar; nos de áudio, troca de modo, Música/A2DP ou Chamada/HFP com microfone, e de codec com um clique, via perfis do PipeWire), Não perturbe, Manter ativo (idle inhibit), perfil de energia (só com o `power-profiles-daemon` já rodando: o shell nunca o ativa, porque isso trava o login e para o auto-cpufreq/tlp); volume, microfone e brilho; histórico de notificações. |
| Atualizações | clique no ícone ao lado do status | Na barra, um check verde quando está tudo em dia e uma seta de download amarela quando há o que atualizar. A gaveta mostra uma tabela com quantos pacotes cada gerenciador tem para atualizar: Sistema (pacman e AUR via yay), Oh My Zsh, Rust (cargo), VS Code Extensions, NeoVim (plugins do lazy.nvim), Node (pacotes globais do npm), Imagens docker, PHP Composer (global), GitHub (extensões e skills do `gh`), Claude Code (e seus plugins) e Python UV (ferramentas do uv). "Verificar" consulta de novo. O botão âmbar "Upgrade" roda o [topgrade](https://github.com/topgrade-rs/topgrade) só nos gerenciadores com pendências, e a saída aparece num painel que sobe da borda de baixo da tela (90% da largura, um terço da altura) e fecha sozinho quando o upgrade termina. Detalhes abaixo. |
| Sessão | `SUPER+CTRL+Q` ou botão ⏻ | Funciona como um DHD: escolha a tecla e confirme no domo vermelho. Duplo clique executa direto. |
| Lançador | `SUPER+D` ou glifo de origem | Funciona como o computador de discagem do SGC: cada letra digitada codifica um chevron e gira o anel de glifos, o app selecionado aparece no horizonte de eventos e Enter trava o 7º chevron e abre o buraco de minhoca (inicia o app). Começando com `>`, disca um comando. |
| Cubo de workspaces | `SUPER+1…0`, `SUPER+SHIFT+1…0` (move a janela junto), `SUPER+Tab`/`SUPER+SHIFT+Tab`, `SUPER+roda do mouse`, roda sobre o número na barra | Trocar de workspace gira um cubo na vertical no monitor onde a troca acontece: o workspace seguinte sobe de baixo, o anterior desce de cima, com janelas e wallpaper nas faces e luz ciano nas arestas. A barra fica parada. Detalhes abaixo. |
| Fechar janela | `SUPER+Q` | A janela é sugada por um Stargate no estilo de SG-1 (anel de aço com glifos): o portal abre sobre ela, as lâmpadas dos nove chevrons acendem uma a uma, o horizonte de eventos azul se forma, a janela gira e cai nele, e o portal se fecha com um clarão e uma onda de choque. Detalhes abaixo. |
| Previsão do tempo | — | Placa na área de trabalho, por baixo das janelas, que pode ser arrastada para qualquer ponto do monitor. Mostra o tempo com uma animação leve (sol, lua com estrelas, nuvens brancas, nuvens cinza com chuva, garoa ou neve, nuvens escuras com raios, neblina), a temperatura, a sensação térmica e a direção e a velocidade do vento. Um clique abre a tabela das próximas 6 horas (temperatura, sensação, chance de chuva e vento). A engrenagem escolhe a cidade, digitada e procurada por nome (nada de GeoIP), e o monitor. Dados do [Open-Meteo](https://open-meteo.com), atualizados a cada 15 minutos. A animação para quando janelas lado a lado cobrem a área de trabalho. |
| Wallpapers | `SUPER+CTRL+W` | Carrossel de placas inclinadas. `SUPER+SHIFT+W` sorteia um wallpaper. |
| Notificações | — | Servidor próprio: popups, ações e histórico. |
| OSD | teclas de volume/brilho | — |
| Lock screen | — | `hypr/hyprlock.conf.in`, opcional (`./install.sh --hyprlock`). |
| Apps no modo escuro | — | Qt 5 e 6 via qt5ct/qt6ct (estilo Fusion com a paleta Ancient, `apps/qt*ct/colors/ancient.conf`); GTK 3 com Adwaita-dark; GTK 4/libadwaita e Electron com `color-scheme prefer-dark`. |

As gavetas descem da barra, presas a ela por uma costura luminosa. Fecham com `Esc` ou com um clique fora.

O `hypr/init.lua` também faz as ferramentas do NetworkManager abrirem flutuando e centralizadas, em vez de lado a lado: o `nm-connection-editor`, os diálogos do `nm-applet` (senha de Wi-Fi, informações da conexão) e os de login de VPN (`nm-*-auth-dialog`).

### Como o cubo funciona

O Hyprland não tem essa animação, então o shell a desenha numa camada própria (`ancient-cube`, abaixo da barra):

1. Captura a tela como está; ela vira a face da frente, congelada.
2. Com o cubo já na tela, pede a troca ao Hyprland. O cubo se afasta até a face ocupar cerca de 80% da tela (240 ms), gira (520 ms) e se aproxima de novo até a face nova preencher a tela (240 ms).
3. A face nova é montada a partir das peças, porque a tela coberta não pode ser capturada: o wallpaper e cada janela capturada onde o Hyprland a colocou. Algumas janelas o Hyprland não exporta (o Firefox, por exemplo). No lugar delas entra o recorte da última foto desse workspace, guardada na última vez que o cubo saiu dele, ou um painel com o nome do app, se não houver foto.
4. O cubo some num fade curto sobre o workspace real.

As teclas chamam atalhos globais do shell (`ancient:go-<alvo>` e `ancient:move-<alvo>`) só enquanto a barra está no ar. Sem o shell, elas trocam de workspace direto pelo Hyprland, então nunca param de funcionar. O cubo gira no monitor onde o workspace aparece, mesmo que o foco esteja em outro: no workspace aberto ali, ou no monitor a que uma regra do Hyprland o prende (`workspace 8 → DP-1`), se ele ainda não existir. Um workspace que já está na tela de outro monitor (o Hyprland só move o foco para lá), nomeado ou especial troca sem cubo. Uma troca pedida durante a animação espera o cubo terminar e então é refeita a partir do workspace em que ele parou. Para desligar o cubo, use `"workspaceCube": false` no config.

### Como o fechamento pelo Stargate funciona

Uma janela que já fechou não pode mais ser desenhada, então o shell a guarda antes, numa camada própria (`ancient-gate`, acima de tudo):

1. Captura a tela como está e cobre a janela com essa foto congelada.
2. Com a foto na tela, desliga a animação de fechamento do Hyprland só para essa janela e pede para fechá-la.
3. Quando o Hyprland avisa que ela fechou, o portal abre sobre a foto e a engole (`windowfx/shaders/gate.frag`, cerca de 1,2 s).

Só o `SUPER+Q` passa pelo portal, e só com o shell no ar (atalho global `ancient:close-window`); sem o shell, ele fecha a janela direto pelo Hyprland. Janelas fechadas de outro jeito (o próprio botão, o app saindo) mantêm a animação do Hyprland. Um app que pergunta antes de fechar (trabalho não salvo) fica aberto: a foto some e a janela recebe a animação de volta. Para desligar o portal, use `"gateClose": false` no config. Depois de editar o shader, gere o `.qsb` de novo com `/usr/lib/qt6/bin/qsb --qt6 -o gate.frag.qsb gate.frag` e reinicie o shell (`qs -c ancient kill` e abra de novo): recarregar a config não troca um shader já carregado.

Em notebooks híbridos (Intel ou AMD mais NVIDIA), o `hypr/init.lua` inicia o shell na GPU integrada, a mesma em que o Hyprland compõe, mesmo que a sessão mande os apps para a NVIDIA. Na NVIDIA, cada captura atravessa as GPUs pela memória e leva de 3 a 5 vezes mais tempo. Os apps abertos pelo shell (lançador, central de controle, sessão) são executados pelo Hyprland e por isso continuam recebendo o ambiente da sessão.

### Como os efeitos de música funcionam

- O espectro vem do [cava](https://github.com/karlstav/cava), lendo a saída de áudio do PipeWire (64 bandas a 60 quadros por segundo). Ele só roda enquanto o player toca e algum efeito está ligado; com a música pausada, o shell volta a ficar parado.
- As batidas são os picos dos graves acima da média recente. Elas puxam o zoom, o brilho e o tremor do wallpaper, e aceleram as partículas.
- O visualizador é um fragment shader só (`wallpaper/shaders/visualizer.frag`), desenhado na camada do wallpaper de cada monitor. Depois de editar o shader, gere o `.qsb` de novo com `/usr/lib/qt6/bin/qsb --qt6 -o visualizer.frag.qsb visualizer.frag` (pacote `qt6-shadertools`).
- A letra sincronizada vem do [LRCLIB](https://lrclib.net), um acervo aberto e gratuito. Com a letra ligada, o shell manda o artista e o título da faixa para o lrclib.net, uma vez por faixa e sessão. Desligue a letra no painel para não enviar nada.
- As escolhas do painel ficam em `~/.local/state/quickshell/by-shell/<id>/music-fx.json`.

### Annabelle

A forma "Annabelle" recria a ovelha da visualização do RealPlayer do início dos anos 2000, desenhada em vetor (`wallpaper/annabelle/`), numa janela redonda que o anel de raios do espectro contorna.

- **Ela ouve a música com você.** O andamento sai do próprio espectro: o quanto ele sobe de um quadro para o outro marca os ataques, a autocorrelação dos últimos 8 s dá o período da batida (de ~70 a ~170 bpm), e um pente com esse período alinhado aos ataques diz onde as batidas caem. Um relógio nesse andamento, puxado de leve para as batidas, comanda os passos. Ele vai adiantado o quanto o espectro atrasa em relação ao som (~80 ms), e cada movimento é adiantado o quanto a sua suavização o atrasa, para que joelhos, cabeça e cascos desçam na hora em que a batida soa, e não um instante depois. Uma virada ou um trecho com acentos deslocados não a tira do tempo; ela só muda de fase se a batida aparecer em outro lugar por 4 s seguidos. Com batida firme e som cheio ela dança mais: joelhos que descem em cada batida e cabeça balançando, um casco batendo por vez (sapateado), e no auge o sapateado em dobro, orelhas sacudindo e pulos que aterrissam na batida seguinte (ou no meio dela, numa música lenta). Num trecho bem mais calmo que o resto da música, fecha os olhos e balança; quando a música volta, pula de olhos arregalados. Ela canta junto quando há voz na música (sempre com o microfone, e muitas vezes enquanto uma linha da letra sincronizada está sendo cantada). Numa faixa nova, levanta as orelhas, olha para você e começa a ouvir o andamento do zero.
- **Cenários** trocam ao acaso, sem ordem, numa batida forte, a cada 16–36 s: dia no pasto, noite com lua e estrelas cadentes (que piscam com os agudos), discoteca com globo espelhado, psicodélico (céu e grama numa cor que gira com a música) e filme antigo (cinza, com poeira e riscos).
- **Visuais** mudam junto com o cenário: clássico, óculos escuros com tatuagem ☮, tatuagem anarquista Ⓐ, cartola com microfone, moicano roxo, boina vermelha.
- **Visitas** de vez em quando: um disco voador que a levanta no raio trator enquanto ela faz caretas, uma bola de praia que quica nas costas dela em cada batida, um passarinho que pousa nas costas dela, dança junto e pia notas, um dirigível com o espectro na tela.

### Como as atualizações funcionam

`scripts/upgrades.py check` consulta os gerenciadores em paralelo, sem instalar nada, um minuto depois do login e a cada 3 horas. Cada número é o que o passo correspondente do topgrade mudaria, então um upgrade leva a contagem a zero:

| Gerenciador | Como conta | Passo do topgrade |
|---|---|---|
| Sistema | `checkupdates` (cópia temporária dos bancos do pacman, sem root) e `yay -Qua` | `system` |
| Oh My Zsh | `git fetch` e commits atrás do `origin/master` (conta 1; o topgrade não atualiza os plugins em `custom/`) | `shell` |
| Rust | `cargo install-update --list --git` | `cargo` |
| VS Code Extensions | versão instalada contra a última do Marketplace compatível com o VS Code e a plataforma (as fixadas ficam de fora) | `vscode` |
| NeoVim | o próprio check do lazy.nvim, num Neovim headless com a sua config | `vim` |
| Node | `npm outdated -g` (versão "wanted") com o Node de `upgradesNodeBin` | `node` |
| Imagens docker | digest da tag no registro (requisição `HEAD`, anônima, que não gasta o limite do Docker Hub) contra o da imagem local; imagens construídas localmente ficam de fora. Com o daemon parado, não consulta (e não o acorda) | `containers` |
| PHP Composer | `composer global update --dry-run` | `composer` |
| GitHub | `gh extension upgrade --all --dry-run` e `gh skill update --all --dry-run` | `github_cli_extensions`, `github_cli_skills` |
| Claude Code | versão instalada contra o canal de releases (`autoUpdatesChannel`), e plugins cujo marketplace lista outra versão | `claude_code`, `claude_code_plugins` |
| Python UV | `uv tool list --outdated`, o próprio uv (quando ele pode se atualizar) e Pythons gerenciados pelo uv com patch novo | `uv` |

O upgrade roda `topgrade --no-tmux --no-self-update --no-ask-retry --yes --only <passos>` num processo destacado do shell, que continua mesmo que o shell reinicie (um pacman interrompido no meio deixaria o sistema pela metade). A saída, sem cores, é acrescentada ao log (`upgradesLog` no config, por padrão `~/upgrade.log`), com um cabeçalho e o código de saída de cada execução. Um shell que reinicia durante o upgrade volta a acompanhá-lo, e o ícone de atualizações gira enquanto ele roda (o clique mostra ou esconde a saída). Enquanto isso, o desligamento e a suspensão ficam bloqueados (`systemd-inhibit`), e um upgrade pedido no meio de uma verificação espera ela terminar. O painel fecha ao terminar, com ou sem falhas: o topgrade avisa o resultado numa notificação, e a gaveta mostra quando o último upgrade falhou. Sem terminal, o sudo não tem onde pedir senha: o passo do sistema precisa de sudo sem senha para o pacman.

## Dependências

Os nomes dos pacotes são os do Arch Linux; em outras distribuições, instale os equivalentes. A linha Sistema do módulo de atualizações só funciona no Arch e derivados, porque conta com pacman e yay. Testado com Hyprland 0.57.2 e Quickshell 0.3.2.

### Obrigatórias

| Dependência | Pacote | Para quê |
|---|---|---|
| Hyprland, com config em Lua (`hyprland.lua`) | `hyprland` | O compositor em que o shell roda. |
| Quickshell | `quickshell` | Roda o shell. |
| PipeWire, com o servidor PulseAudio e o WirePlumber | `pipewire`, `pipewire-pulse`, `wireplumber` | Volume, microfone, o OSD, os efeitos de música e os perfis de áudio Bluetooth (via `pactl`). |
| Material Symbols Rounded | `ttf-material-symbols-variable-git` (AUR) | Os ícones do shell inteiro. |

As fontes Orbitron e Rajdhani vêm no repositório, e o instalador cria os links delas.

### Opcionais

Cada uma só é necessária para o recurso ao lado.

| Recurso | Pacotes |
|---|---|
| Wi-Fi e redes conhecidas na central de controle | `networkmanager`; `nm-connection-editor` para "Editar" e o clique direito (`networkSettingsCommand`) |
| Bluetooth na central de controle | `bluez`, com o `bluetooth.service` habilitado; `blueman` para o clique direito (`bluetoothSettingsCommand`) |
| Bateria na barra | `upower` |
| Perfil de energia na central de controle | `power-profiles-daemon`, já rodando (o shell nunca o inicia) |
| Brilho e o OSD dele | `brightnessctl` |
| Efeitos de música | `cava` |
| Previsão do tempo e letra sincronizada | `curl` e acesso à internet |
| Lock screen (`--hyprlock`) | `hyprlock`; `imagemagick` para o fundo desfocado. O menu de sessão bloqueia com `loginctl lock-session` (`lockCommand`), que só funciona quando algo trata esse sinal, como o `hypridle` com `lock_cmd = pidof hyprlock \|\| hyprlock` |
| Atualizações de pacotes | `python`, `pacman-contrib` (`checkupdates`) e `topgrade` (AUR); `yay` (AUR) para contar os pacotes do AUR. Os outros gerenciadores (cargo, npm, uv…) só são consultados quando estão instalados |
| Notificação com o destino depois do splash de boot | `libnotify` (`notify-send`) |
| Texto monoespaçado (launcher, saída do upgrade) | `ttf-firacode-nerd` |
| Apps Qt escuros | `qt5ct`, `qt6ct` |
| Apps de terminal no launcher | um entre `kitty`, `foot`, `alacritty`, `ghostty`, `konsole` e `xterm` (`terminal` na config) |

Tudo de uma vez:

```sh
sudo pacman -S --needed hyprland quickshell pipewire pipewire-pulse wireplumber \
    networkmanager nm-connection-editor bluez blueman upower brightnessctl cava curl \
    hyprlock hypridle imagemagick python pacman-contrib libnotify ttf-firacode-nerd qt5ct qt6ct
yay -S --needed ttf-material-symbols-variable-git topgrade   # AUR, com o yay ou outro helper
```

### Para desenvolvimento

| Tarefa | Pacote |
|---|---|
| Editar os shaders (`qsb`) | `qt6-shadertools` |
| Traduções (`xgettext`, `msgmerge`, `msgfmt`) | `gettext` |
| Gerar os wallpapers de novo (`rsvg-convert`) | `librsvg` |

O resto da preparação para desenvolver está no [CONTRIBUTING.md](CONTRIBUTING.md) (em inglês).

## Instalar

Funciona em qualquer Hyprland com config em Lua (`hyprland.lua`), seja a sua própria ou a de um pacote de dotfiles. Instale as [dependências](#dependências) antes.

```sh
./install.sh                      # links, fontes, fragmento do Hyprland, apps escuros e config.json
./install.sh --entry ARQUIVO.lua  # carrega o fragmento desse arquivo em vez do hyprland.lua
./install.sh --disable-autostart  # também desativa o autostart de barras e daemons que o shell substitui
./install.sh --hyprlock           # também usa o lock screen Ancient (faz backup do hyprlock.conf)
./install.sh --now                # troca o shell da sessão atual imediatamente
./install.sh --uninstall          # desfaz tudo (com --now, reinicia o que estava desativado)
```

O que o instalador faz:

- Linka `quickshell/ancient` em `~/.config/quickshell/ancient`, as fontes em `~/.local/share/fonts/ancient-shell` e `hypr/` em `~/.config/hypr/ancient-shell` (respeitando `XDG_CONFIG_HOME` e `XDG_DATA_HOME`).
- Procura `require("ancient-shell/init")` em todos os `.lua` de `~/.config/hypr`, seguindo links para arquivos e pastas (como os do GNU stow). Se não achar, acrescenta a linha no fim do `hyprland.lua`, ou do arquivo passado em `--entry`. Use `--entry` quando os seus dotfiles sobrescrevem o `hyprland.lua` em atualizações e têm um arquivo próprio para customizações, carregado por ele. A linha precisa vir depois dos seus atalhos, porque o fragmento troca os atalhos que usa (`SUPER+D`, `SUPER+Q`, `SUPER+1…0`…).
- Cria `~/.config/ancient-shell/config.json` se ele não existir, com a pasta de wallpapers (`Wallpapers` dentro da pasta de imagens do `xdg-user-dir`, para onde copia os wallpapers do repositório) e o primeiro terminal instalado entre kitty, foot, alacritty, ghostty, konsole e xterm.
- `--disable-autostart` comenta, em qualquer `.lua` de `~/.config/hypr`, as linhas `hl.exec_cmd("…")` que iniciam waybar, swaync, mako, dunst, fnott, hyprpaper, swww, swaybg, wpaperd, hyprpanel ou outra config do Quickshell. Só entram linhas que são uma chamada inteira com um único texto entre aspas (`hl.exec_cmd("waybar")`): comentar uma linha de uma chamada que continua na seguinte, ou que tem outras instruções, quebraria a config, e um comando montado com `..` não teria como ser reiniciado. Elas ficam marcadas com `-- [ancient-shell]`, e o `--uninstall` as restaura. Com `--now`, esses programas são encerrados (as outras configs do Quickshell, com `qs -c <nome> kill`). Um desses programas que esteja rodando, mas é iniciado de outro lugar, gera um aviso: se for um serviço do systemd de usuário (o pacote do hyprpaper, por exemplo, já vem com o `hyprpaper.service` habilitado), o aviso traz o `systemctl --user disable --now` dele; se for um script, desative-o onde ele é iniciado.
- `--hyprlock` gera `~/.config/hypr/hyprlock.conf` a partir de `hypr/hyprlock.conf.in`, com o caminho do cache onde o shell grava o fundo desfocado. Um `hyprlock.conf` que não foi gerado por ele, ou que você editou depois, vira `hyprlock.conf.bak.<data>`, e o `--uninstall` devolve o seu. Depois do primeiro `--hyprlock`, cada `./install.sh` atualiza o arquivo gerado (e troca o link que versões anteriores criavam). Os textos e o formato da data saem no idioma do locale de quem roda o instalador (veja [Traduções](#traduções)).

Para forçar o modo escuro, o instalador troca `~/.config/qt5ct` e `~/.config/qt6ct` por uma configuração própria. A anterior fica guardada em `~/.config/qt5ct.ancient-backup` e `~/.config/qt6ct.ancient-backup`, e o `--uninstall` a devolve. Ele também roda `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` e liga `gtk-application-prefer-dark-theme` nos `settings.ini` do GTK. O `hypr/init.lua` define `QT_QPA_PLATFORMTHEME=qt6ct` (os plugins do qt5ct e do qt6ct aceitam esse nome) e `ADW_DEBUG_COLOR_SCHEME=prefer-dark`. Apps que já estavam abertos só mudam quando forem reabertos.

O `--uninstall` mantém o `config.json` e os wallpapers copiados.

Com config em hyprlang (`hyprland.conf`), o fragmento não carrega: rode `./install.sh` para os links e o `config.json`, inicie o shell com `exec-once = qs -c ancient` e crie os atalhos chamando a IPC (abaixo). O shell em si funciona com as duas sintaxes.

## Configurar

Edite `~/.config/ancient-shell/config.json` (ou `$XDG_CONFIG_HOME/ancient-shell/config.json`). Ele é recarregado sozinho quando muda. Chaves que faltam usam o padrão (uma chave apagada com o shell rodando só volta ao padrão quando ele reinicia), e caminhos podem começar com `~/`.

```json
{
  "wallpaperDir": "~/Pictures/Wallpapers",
  "defaultWallpaper": "",
  "clock24h": true,
  "showSeconds": false,
  "workspaces": 9,
  "terminal": "kitty",
  "lockCommand": "loginctl lock-session",
  "suspendCommand": "systemctl suspend",
  "rebootCommand": "systemctl reboot",
  "poweroffCommand": "systemctl poweroff",
  "networkSettingsCommand": "nm-connection-editor",
  "bluetoothSettingsCommand": "blueman-manager",
  "diskPath": "/",
  "locale": "",
  "workspaceCube": true,
  "gateClose": true,
  "upgradesNodeBin": "",
  "upgradesLog": "~/upgrade.log",
  "upgradesPath": ["~/.cargo/bin", "~/.local/bin"],
  "upgradesDisabled": []
}
```

| Chave | O que é |
|---|---|
| `wallpaperDir` | Pasta dos wallpapers do seletor e do `wallpaper random`. |
| `defaultWallpaper` | Wallpaper enquanto nenhum foi escolhido; vazio usa a primeira imagem de `wallpaperDir`. |
| `terminal` | Abre os apps de terminal do lançador como `<terminal> -e <comando>`. |
| `lockCommand`, `suspendCommand`, `rebootCommand`, `poweroffCommand` | Ações do menu de sessão; vazio tira a ação do menu. |
| `networkSettingsCommand`, `bluetoothSettingsCommand` | Apps abertos pela central de controle; vazio esconde o link e desliga o clique direito. |
| `diskPath` | Ponto de montagem cujo uso aparece no dashboard. |
| `locale` | Locale das datas (por exemplo, `pt_BR`); vazio usa o do ambiente (`LC_ALL`, `LC_TIME`, `LANG`). |
| `workspaceCube`, `gateClose` | Liga o cubo de workspaces e o fechamento pelo Stargate. |
| `upgradesNodeBin` | Pasta `bin` do Node cujos pacotes globais do npm entram nas atualizações (por exemplo, `~/.nvm/versions/node/v22.14.0/bin`); vazio usa o `npm` do PATH. |
| `upgradesLog` | Arquivo onde a saída dos upgrades é acrescentada. |
| `upgradesPath` | Pastas colocadas antes do PATH nas verificações e no upgrade, que rodam com o PATH da sessão (normalmente sem as pastas do usuário). |
| `upgradesDisabled` | Gerenciadores que saem da tabela, das verificações e do upgrade, pelo id: `system`, `omz`, `cargo`, `vscode`, `nvim`, `node`, `docker`, `composer`, `github`, `claude`, `uv` (por exemplo, `["docker"]`). Vale ao salvar. |

As verificações acham as ferramentas nos lugares padrão delas e respeitam as variáveis de cada uma: `ZSH` (Oh My Zsh), `VSCODE_EXTENSIONS` e `CLAUDE_CONFIG_DIR`.

As cores ficam em `quickshell/ancient/theme/Theme.qml`, e as do Hyprland em `hypr/palette.lua`.

## Traduções

Os textos do código estão em inglês, e as traduções ficam em catálogos gettext em `quickshell/ancient/i18n/` (`pt_BR.po` vem pronto). O shell escolhe o idioma pelas variáveis de locale do ambiente em que ele roda, como os programas que usam gettext:

1. O locale das mensagens é o primeiro definido entre `LC_ALL`, `LC_MESSAGES` e `LANG`.
2. Se ele é `C`, `C.UTF-8` ou `POSIX` (ou nenhum está definido), tudo fica em inglês, e `LANGUAGE` é ignorada.
3. Senão, o shell tenta os idiomas de `LANGUAGE` (separados por `:`, por exemplo `pt_BR:en`) e depois o do locale, sem a codificação: cada um com e sem o modificador e a região (`sr_RS@latin`, `sr@latin`, `sr_RS`, `sr`). Vale o primeiro que tem catálogo, inteiro: o que faltar nele fica em inglês. O inglês encerra a lista, porque é o idioma do código (com `LANGUAGE=en:pt_BR`, inglês). Sem nenhum catálogo, inglês.

Os nomes de dias e meses seguem `LC_ALL`, `LC_TIME` ou `LANG`, a menos que `locale` esteja definido no `config.json`. A ordem dos elementos da data vem da tradução, então com `LC_TIME` e `LC_MESSAGES` em idiomas diferentes a data mistura os dois. A busca de cidades da previsão do tempo usa o idioma do catálogo carregado.

O shell herda o ambiente da sessão do Hyprland. Se a sessão roda com `LANG=C.UTF-8` (o padrão do systemd quando `/etc/locale.conf` não define outro), ele fica em inglês. Para português, defina o locale da sessão, por exemplo no `/etc/locale.conf` (`LANG=pt_BR.UTF-8`) ou na config do Hyprland, antes do shell iniciar:

```lua
hl.env("LANG", "pt_BR.UTF-8")
```

As traduções e as datas do shell não dependem do locale estar gerado no sistema (o Qt tem os próprios dados), mas a data do lock screen e os outros programas da sessão dependem: confira com `locale -a` (no Arch, descomente a linha em `/etc/locale.gen` e rode `locale-gen`). Depois de trocar, reinicie o shell (`qs -c ancient kill` e abra de novo, ou saia da sessão).

O script de atualizações (`scripts/upgrades.py`) usa os mesmos catálogos e a mesma regra. O lock screen é traduzido quando o `install.sh` gera o `hyprlock.conf`, no locale de quem roda o instalador; rode `./install.sh` de novo depois de trocar de idioma.

### Adicionar um idioma

Precisa do GNU gettext (`xgettext`, `msginit`, `msgmerge`, `msgfmt`).

```sh
cd quickshell/ancient/i18n
msginit --no-translator -l fr_FR -i ancient-shell.pot -o fr.po   # ou fr_FR.po, se for de uma região
# traduza os msgstr do fr.po (Poedit, Lokalize, GTranslator ou um editor de texto)
./update.sh --check
```

No QML, textos traduzíveis passam por `I18n.tr("Text")`, `I18n.tr("Checked at %1", hora)`, `I18n.trn("%1 package", "%1 packages", n)` ou `I18n.trc("contexto", "Text")`; no Python, por `_()` de `scripts/i18n.py`; no `hypr/hyprlock.conf.in`, ficam entre `{{ }}`. Um comentário `i18n:` logo antes vira nota para quem traduz. Depois de mudar textos, rode `quickshell/ancient/i18n/update.sh`: ele regenera o `ancient-shell.pot` e atualiza os `.po`, marcando o que falta traduzir. O shell recarrega o catálogo quando o `.po` muda.

## IPC

```sh
qs -c ancient ipc call shell dial "firefox"      # abre o lançador já preenchido
qs -c ancient ipc call shell launcher|dashboard|media|musicFx|control|session|upgrades|wallpapers|closeAll|dnd
qs -c ancient ipc call upgrades check|run|output|count   # output: mostra/esconde a saída do upgrade
qs -c ancient ipc call musicfx mode bars|wave|mirror|ring|halo
qs -c ancient ipc call musicfx toggle visualizer|particles|lyrics|wallpaperFx|glow|blur|zoom|shake
qs -c ancient ipc call musicfx intensity 150         # em %, de 10 a 200
qs -c ancient ipc call wallpaper set /caminho/img.png | random | get
qs -c ancient ipc call weather toggle|refresh|details|here   # here: traz para o monitor focado
qs -c ancient ipc call weather city "Campinas"            # a primeira cidade com esse nome
qs -c ancient ipc call audio up|down|mute|mic
qs -c ancient ipc call brightness up|down
qs -c ancient ipc call workspace go 3|m+1|e-1      # troca com o cubo
qs -c ancient ipc call workspace move 3            # leva a janela ativa junto
qs -p ~/.config/quickshell/ancient/splash.qml ipc call splash skip|ready
```

A splash roda numa instância própria (`qs -p …/splash.qml`), iniciada pelo `hypr/init.lua` junto com o shell. Assim ela aparece mesmo que o shell demore. Ela sabe que o shell está pronto ao consultar `ipc show` dele. Para desligá-la, comente a linha `hl.exec_cmd(SPLASH .. " -d")`.

Quando o shell inicia e quando o wallpaper muda, `scripts/wallpaper-hook.sh` gera `$XDG_CACHE_HOME/ancient-shell/lock.png` (`~/.cache/ancient-shell/lock.png`), a versão desfocada que o hyprlock usa de fundo. Se o fundo daquele wallpaper já existe, ele não faz nada.

## Estrutura

```
quickshell/ancient/
  shell.qml          raiz + IPC
  splash.qml         splash de boot (instância separada)
  theme/             paleta, fontes, métricas
  widgets/           ChamferPanel, OriginGlyph, GlyphSlider, RingGauge…
  services/          Config, I18n, ShellState, Audio, Brightness, SysStats, Notifs, Wallpapers, Players, Hypr, WorkspaceNav, WindowClose, MusicFx, Lyrics, Weather, Upgrades
  scripts/           wallpaper-hook.sh, upgrades.py (contagem de atualizações e o upgrade pelo topgrade), i18n.py (traduções do Python e do lock screen)
  i18n/              catálogos de tradução (ancient-shell.pot, pt_BR.po) e update.sh
  workspace/         cubo de troca de workspace (Cube, WorkspaceCube, WorkspaceFace)
  wallpaper/         wallpaper com os efeitos de música, visualizador (shaders/) e letra
  weather/           widget de previsão do tempo (WeatherWidget, WeatherScene)
  windowfx/          janela fechando sugada por um Stargate (GateClose, shaders/)
  bar/  drawers/  notifications/  launcher/  wallpaper/  osd/  splash/
  assets/fonts/      Orbitron e Rajdhani (SIL OFL)
hypr/                init.lua, palette.lua, hyprlock.conf.in (modelo do lock screen)
apps/qt5ct/ qt6ct/   paleta Qt escura e modelos do qt5ct.conf/qt6ct.conf
wallpapers/          earth_origin.png e pegasus_chart.png (3840×2160, o mapa estelar dos Anciões), com os scripts que os geram em vetor
```

## Referências

Inspirado em posts do r/unixporn: Vitreus/pleamar (painéis que brotam da barra), o seletor de wallpapers em Quickshell, ETEA e um KDE "tuned just right".

## Como contribuir

Relatos de bugs, ideias, traduções, código e arte são bem-vindos. O [CONTRIBUTING.md](CONTRIBUTING.md) (em inglês) explica como preparar uma cópia de desenvolvimento, as convenções do projeto e o que um pull request precisa ter.

## Licença

O Ancient Shell é distribuído sob a [licença MIT](LICENSE.txt). As fontes Orbitron e Rajdhani em `quickshell/ancient/assets/fonts/` são obras de terceiros sob a SIL Open Font License; os textos dessas licenças estão ao lado delas.
