Function un.onInit
  !insertmacro check64BitAndSetRegView

  ${IfNot} ${Silent}
    !ifdef ONE_CLICK
      MessageBox MB_OKCANCEL "$(areYouSureToUninstall)" IDOK +2
      Quit

      # one-click installer executes uninstall section in the silent mode, but we must show message dialog if silent mode was not explicitly set by user (using /S flag)
      !insertmacro CHECK_APP_RUNNING
      SetSilent silent
    !endif
  ${endIf}

  !insertmacro initMultiUser

  !ifmacrodef customUnInit
    !insertmacro customUnInit
  !endif
FunctionEnd

Section "un.install"
  !ifndef ONE_CLICK
    # for boring installer we check it here to show progress
    !insertmacro CHECK_APP_RUNNING
  !endif

  !insertmacro setLinkVars

  ClearErrors
  ${GetParameters} $R0
  DetailPrint $R0
  ${GetOptions} $R0 "--keep-shortcuts" $R1
  DetailPrint $R1
  ${if} ${Errors}
    WinShell::UninstAppUserModelId "${APP_ID}"
    WinShell::UninstShortcut "$startMenuLink"
    WinShell::UninstShortcut "$desktopLink"

    Delete "$startMenuLink"
    Delete "$desktopLink"

    # Refresh the desktop
    System::Call 'shell32::SHChangeNotify(i, i, i, i) v (0x08000000, 0, 0, 0)'
  ${endif}

  !ifmacrodef unregisterFileAssociations
    !insertmacro unregisterFileAssociations
  !endif

  # delete the installed files
  !ifmacrodef customRemoveFiles
    !insertmacro customRemoveFiles
  !else
    RMDir /r /REBOOTOK $INSTDIR
  !endif

  Var /GLOBAL isDeleteAppData
  StrCpy $isDeleteAppData "0"

  ClearErrors
  ${GetOptions} $R0 "--delete-app-data" $R1
  ${if} ${Errors}
    !ifdef DELETE_APP_DATA_ON_UNINSTALL
      ${ifNot} ${Updated}
        StrCpy $isDeleteAppData "1"
      ${endif}
    !endif
  ${else}
    StrCpy $isDeleteAppData "1"
  ${endIf}

  ${if} $isDeleteAppData == "1"
    # electron always uses per user app data
    ${if} $installMode == "all"
      SetShellVarContext current
    ${endif}
    RMDir /r "$APPDATA\${APP_FILENAME}"
    !ifdef APP_PRODUCT_FILENAME
      RMDir /r "$APPDATA\${APP_PRODUCT_FILENAME}"
    !endif
    ${if} $installMode == "all"
      SetShellVarContext all
    ${endif}
  ${endif}

  DeleteRegKey SHCTX "${UNINSTALL_REGISTRY_KEY}"
  DeleteRegKey SHCTX "${INSTALL_REGISTRY_KEY}"

  !ifmacrodef customUnInstall
    !insertmacro customUnInstall
  !endif

  !ifdef ONE_CLICK
    !insertmacro quitSuccess
  !endif
SectionEnd