<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require __DIR__ . '/vendor/autoload.php';

$host = 'https://mainnet.demo.btcpayserver.org';
$apiKey = 'e7081c8468fc3f305d78e1051e38dca8a6646644';
$storeId = 'EnLY7ZrBvSmLzTDWyMx9sjyJFfBjt5fGwBAnZXkCTbQf';

?>
<!DOCTYPE html>
<html>
<head>
    <title>BTCPay Invoice</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .status-message {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 5px;
            background: #e8f5e9;
            color: #2e7d32;
        }
        .invoice-frame {
            width: 100%;
            height: 700px;
            border: none;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .checkout-link {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            background: #1976d2;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .checkout-link:hover {
            background: #1565c0;
        }
        .amount-form {
            margin-bottom: 20px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .amount-input {
            padding: 10px;
            font-size: 16px;
            border: 1px solid #ddd;
            border-radius: 4px;
            margin-right: 10px;
        }
        .submit-button {
            padding: 10px 20px;
            background: #1976d2;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        .submit-button:hover {
            background: #1565c0;
        }
    </style>
</head>
<body>
    <div class="container">
        <?php
        if (!isset($_POST['amount'])) {
            ?>
            <h2>Create Bitcoin On-chain Payment Invoice</h2>
            <form method="POST" class="amount-form">
                <label for="amount">Enter amount in SAT (minimum 10000 sats recommended): </label>
                <input type="number" 
                       name="amount"
                       id="amount" 
                       step="1" 
                       min="10000" 
                       required 
                       class="amount-input" 
                       placeholder="Enter amount in SATs">
                <button type="submit" class="submit-button">Create Bitcoin Invoice</button>
            </form>
            <?php
        } else {
            try {
                $amount = intval($_POST['amount']);
                
                if ($amount < 10000) {
                    throw new Exception("Amount must be at least 10000 sats for on-chain transactions");
                }

                $client = new \BTCPayServer\Client\Store($host, $apiKey);
                
                // Try to get store info to verify API key works
                $store = $client->getStore($storeId);
                
                // Convert satoshis to BTC
                $btcAmount = $amount / 100000000;
                
                // Create the invoice with on-chain Bitcoin specified
                $invoiceClient = new \BTCPayServer\Client\Invoice($host, $apiKey);
                $invoice = $invoiceClient->createInvoice(
                    $storeId,
                    'SATS',
                    \BTCPayServer\Util\PreciseNumber::parseString($amount),
                    'TEST-' . time(),
                    null,
                    [
                        'paymentMethods' => ['BTC'],
                        'defaultPaymentMethod' => 'BTC'
                    ]
                );
                
                // Get the checkout URL
                $checkoutUrl = $invoice->getData()['checkoutLink'];
                
                // Display success messages
                echo '<div class="status-message">';
                echo '<p>✓ API Connection successful</p>';
                echo '<p>✓ Bitcoin On-chain Invoice created successfully for ' . number_format($amount) . ' sats';
                echo ' (' . number_format($btcAmount, 8) . ' BTC)</p>';
                echo '</div>';
                
                // Display the invoice iframe
                echo '<h2>Pay Invoice (Bitcoin On-chain)</h2>';
                echo '<iframe src="' . $checkoutUrl . '" class="invoice-frame"></iframe>';
                
                // Display the direct checkout link
                echo '<p><a href="' . $checkoutUrl . '" target="_blank" class="checkout-link">';
                echo 'Open in New Window</a></p>';
                
                // Add a button to create new invoice
                echo '<p><a href="' . $_SERVER['PHP_SELF'] . '" class="checkout-link" style="background: #4caf50;">';
                echo 'Create New Invoice</a></p>';
                
            } catch (\Throwable $e) {
                echo '<div class="status-message" style="background: #ffebee; color: #c62828;">';
                echo "Error: " . $e->getMessage() . "\n";
                echo '</div>';
                echo '<p><a href="' . $_SERVER['PHP_SELF'] . '" class="checkout-link">Try Again</a></p>';
            }
        }
        ?>
    </div>
</body>
</html>
