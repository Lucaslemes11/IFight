# LEIAME – IFigth: Sistema Obrigatório de 10 Pontos

## 1. Informações gerais

- *Nome do sistema:* IFigth  
- *Versão do sistema:* BETA  
- *Linguagem utilizada:* Dart  
- *Banco de Dados:* Firebase Firestore  
- *Sistema operacional utilizado para desenvolvimento:* Windows 10  
- *Sistema operacional para execução:* Android (mínimo 5.0 – API 21)  
- *IDE utilizada:* Visual Studio Code 1.105.1 (com extensão Flutter 3.120.0)  
- *Versão do Flutter:* 3.35.4 (Dart 3.9.2)  
- *Data de entrega:* 07/10  

*Integrantes:*  
- Lucas Lemes – 20223029437 – 20223029437@estudantes.ifpr.edu.br  
- Allan – 2022302211 – 2022302211@estudantes.ifpr.edu.br  
- Khadija – 20223022196 – 20223022196@estudantes.ifpr.edu.br  

## 2. Pré-requisitos para compilação

1. Windows 10 (64 bits)  
2. Flutter SDK  
3. Android Studio  
4. IDE: Android Studio ou VS Code com plug-ins  

*OBS:* Todos os pré-requisitos já estão na pasta prereqs/. Basta executar os instaladores.

### 2.1 Instalar Flutter SDK

1. Abra a pasta prereqs/flutter/ que está no pendrive.  
2. Extraia para algo como: C:\src\flutter  
3. Configure a variável de ambiente PATH:  
   - Clique com o botão direito em *Este Computador → Propriedades → Configurações avançadas → Variáveis de Ambiente*  
   - Em *Variáveis do sistema*, selecione Path → *Editar* → *Novo* → adicione: C:\src\flutter\bin  
4. Abra o terminal (CMD ou PowerShell) e digite:
    flutter --version
    Deve aparecer algo como:  
### 2.2 Instalar Android Studio

1. Abra a pasta prereqs/android-studio/ no pendrive.  
2. Execute o instalador .exe e siga as instruções padrão.  
3. Marque as opções: *Android SDK, **Android SDK Platform* e *Android Virtual Device (AVD)*.  
4. Após a instalação, abra o Android Studio → *Configurar → SDK Manager*  
   - Confirme se a versão do SDK é pelo menos *36.1.0*.  
5. Abra o terminal e aceite as licenças do Android SDK: 
flutter doctor --android-licenses
Digite y para aceitar todas.

### 2.3 Instalar Plug-ins VS Code

1. Abra o VS Code.  
2. Clique no ícone de quadrados na barra lateral ou pressione *Ctrl + Shift + X*.  
3. Pesquise por *Dart, localize a extensão oficial (Publisher: Dart Code) → clique em **Install*.  
4. Pesquise por *Flutter, localize a extensão oficial → clique em **Install*.  
5. Verifique a instalação:

- Todos os itens essenciais devem aparecer com ✔ (exceto Visual Studio, que não é necessário para Android).

## 3. Verificação

- Execute: flutter doctor

- Todos os itens essenciais devem aparecer com ✔.  
- O alerta sobre Visual Studio só é relevante para desenvolvimento de apps Windows Desktop e pode ser ignorado para Android.

## 4. Baixar dependências e compilar

1. Extraia o código-fonte que está em codigo fonte/ para um local de sua preferência.  
2. No VS Code → *File → Open Folder* → selecione a pasta extraída.  
3. Abra o terminal e execute:

- Todos os itens essenciais devem aparecer com ✔.  
- O alerta sobre Visual Studio só é relevante para desenvolvimento de apps Windows Desktop e pode ser ignorado para Android.

## 4. Baixar dependências e compilar

1. Extraia o código-fonte que está em codigo fonte/ para um local de sua preferência.  
2. No VS Code → *File → Open Folder* → selecione a pasta extraída.  
3. Abra o terminal e execute: flutter upgrade 

- e execute novamente flutter pub get

5. Para compilar no celular Android:  
   - Ative as *Opções de desenvolvedor* no celular:  
     - Vá em *Configurações → Sobre o telefone → Número da compilação* → clique 7 vezes.  
     - Volte em *Opções de desenvolvedor* → ative *Depuração USB*.  
   - Conecte o celular ao computador e permita a depuração quando solicitado.  
   - Seu dispositivo aparecerá listado em:
    flutter devices
    -Para copilar e usar o app 
    -flutter run
