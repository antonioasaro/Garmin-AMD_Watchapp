<?PHP

  if (!isset($_GET['stock'])) die();
  $stock = $_GET['stock'];

  $url = "https://www.google.com/finance/info?q=" . $stock;
  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_TIMEOUT, 5);
  curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  $data = curl_exec($ch);
  curl_close($ch);

  $data = str_replace("//", "", $data);
  $data = str_replace("[",  "", $data);
  $data = str_replace("]",  "", $data);
  $data = str_replace("{",  "", $data);
  $data = str_replace("}",  "", $data);
  $data = str_replace("\n", "", $data);
  $data = str_replace(" ",  "", $data);
  
  $datafields = split(",", $data);
  $l_cur_field = $datafields[5];
  $l_cur_price = split(":", $l_cur_field);
  $stockprice = str_replace("\"", "", $l_cur_price[1]);
  $results["price"] = $stockprice;
  header('Content-Type: application/json');
  echo json_encode($results);

?>

