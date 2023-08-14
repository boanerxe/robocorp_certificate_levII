*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Tasks ***
Order Robots From RobotSpareBin Industries Inc.
    Open the robot order website
    ${orders}=    Get orders
    Loop the orders    ${orders}
    Create ZIP package from PDF files
    [Teardown]    Cleanup temporary directories and finish

    


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${temp_csv}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${temp_csv}

Loop the orders
    [Arguments]    ${orders}
    FOR     ${order}     IN     @{orders}
        Wait And Click Button    css:button.btn-dark    #Aviso de cookies o similar
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    5 times    2 seconds    Submit Order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Return to order form
    END
    
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button When Visible    id:preview

Submit Order
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button    id:order
    Element Should Be Visible    id:receipt


Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${file_path}=   Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${file_path}
    RETURN    ${file_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${file_path}=   Set Variable    ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${file_path}
    RETURN     ${file_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}    0.2    

Return to order form
    Click Button    id:order-another

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts${/}    ${zip_file_name}


Cleanup temporary directories and finish
    Remove Directory    ${OUTPUT_DIR}${/}receipts${/}    ${True}
    Remove Directory    ${OUTPUT_DIR}${/}screenshots${/}    ${True}
    Close Browser
