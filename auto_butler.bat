set pathToSend=C:\Users\Tiamo\Documents\Programming\Games\Windup Wizards\non_game\deliverables
set butlerName=pandaqi/windup-wizards

butler push "%pathToSend%\windows" %butlerName%:windows
butler push "%pathToSend%\mac" %butlerName%:mac
butler push "%pathToSend%\linux" %butlerName%:linux
butler push "%pathToSend%\HTML5" %butlerName%:html5
butler push "%pathToSend%\WindupWizards.apk" %butlerName%:android

pause