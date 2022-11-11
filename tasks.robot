*** Settings ***
Documentation       Orders robots from RoboSpareBin Industries Inc.    Saves the order HTML receipt ass a PDF file.    Saves the screenshot of the ordered robot    Embeds the screenshot of the robot to the PDF receipt    Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       0.5s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${Url}=    Get Url from user
    ${orders}=    Get orders    ${Url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Store the receipt as a PDF file
        ...    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${robospareUrl}=    Get Secret    robotspare
    Open Available Browser    ${robospareUrl}[URL]

Get Url from user
    Add text input    url    label=Provide Url
    ${response}=    Run dialog
    RETURN    ${response.url}

Get orders
    [Arguments]    ${URL}
    Download csv file    ${URL}
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

Download csv file
    [Arguments]    ${downloadLink}
    Download    ${downloadLink}    overwrite=True

Close the annoying modal
    Run Keyword And Ignore Error    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Run Keyword and Continue On Failure    Click Button    preview

Submit the order
    Click Button    order
    FOR    ${i}    IN RANGE    999999
        ${success}=    Is Element Visible    id:receipt
        IF    ${success}            BREAK
        Click Button    id:order
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_${orderNumber}.pdf
    Html To Pdf    ${receipt}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Wait Until Page Contains Element    id:robot-preview-image    timeout=${GLOBAL_RETRY_INTERVAL}
    ${path_screenshot}=    Set Variable    ${OUTPUT_DIR}${/}Screenshots${/}screenshot_${orderNumber}.png
    Screenshot    id:robot-preview-image    ${path_screenshot}
    RETURN    ${path_screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screeshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screeshot}    ${pdf}    ${pdf}
    Close Pdf    ${pdf}

Go to order another robot
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Click Button
    ...    id:order-another
    Wait Until Page Contains Element    css:.modal-content
    Click Button    OK

Create a ZIP file of the receipts
    ${zip_file}=    Set Variable    ${CURDIR}${/}output${/}PDFs.zip
    Archive Folder With Zip    receipts    ${zip_file}
