<?php

// тут код из 1С Битрикс, предшествующий этой строке:

if(($_GET["mode"] == "file") && $ABS_FILE_NAME){
  // тут код из 1С Битрикс
}
// доработка:
elseif(($_GET["mode"] == "report") && $_SESSION["BX_CML2_IMPORT"]["zip"])
{
  if(!array_key_exists("last_zip_entry", $_SESSION["BX_CML2_IMPORT"]))
    $_SESSION["BX_CML2_IMPORT"]["last_zip_entry"] = "";

  $result = CIBlockXMLFile::UnZip($_SESSION["BX_CML2_IMPORT"]["zip"], $_SESSION["BX_CML2_IMPORT"]["last_zip_entry"]);

  if($result===false)
  {
    echo "failure\n",GetMessage("CC_BSC1_ZIP_ERROR");
  }
  elseif($result===true)
  {
    $_SESSION["BX_CML2_IMPORT"]["zip"] = false;
    echo "progress\n".GetMessage("CC_BSC1_ZIP_DONE");
  }
  else
  {
    $_SESSION["BX_CML2_IMPORT"]["last_zip_entry"] = $result;
    echo "progress\n".GetMessage("CC_BSC1_ZIP_PROGRESS");
  }
}
elseif(($_GET["mode"] == "report") && $ABS_FILE_NAME)
{
  $NS = &$_SESSION["BX_CML2_IMPORT"]["NS"];
  $strError = "";
  $strMessage = "";
  $bFileReportImport = "N";
  $bFileReportDataImport = "N";

  $sAbsFileName = str_replace('//', '/', $ABS_FILE_NAME);
  $sReportFilePrefix = str_replace('//', '/', $_SERVER["DOCUMENT_ROOT"]."/upload/1c_catalog/report_");


  if (substr($sAbsFileName, 0, strlen($sReportFilePrefix)) == $sReportFilePrefix)
  {
    $bFileReportImport = "Y";
    $NS["STEP"] = 10;

    foreach(GetModuleEvents("catalog", "OnSuccessCatalogImport1C", true) as $arEvent)
      ExecuteModuleEventEx($arEvent);
  } elseif(preg_match('~data[^.\/]*\.json$~', $sAbsFileName, $m)) {
    $bFileReportDataImport = "Y";
    $NS["STEP"] = 10;
  }
  else
  {
    $strError = "Файл не найден.";
    echo "failure\n";
    echo str_replace("<br>", "", $strError);
  }
}
// /загрузка файлов в раздел Отчёты
elseif(($_GET["mode"] == "checkRezerv"))
{
  \Vendor\Dealer\Parser\Legacy::exportRezervFile();
  die();
}
