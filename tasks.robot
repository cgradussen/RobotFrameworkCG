*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp
${OUTPUT_DIR}=                      ${CURDIR}${/}output


*** Tasks ***
# Order robots from RobotSpareBin Industries Inc
# Run Keyword And Continue On Failure
Order Robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Wait Until Keyword Succeeds    10x    1.0 sec    Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    1.0 sec    Order the robot
        Download and store the result    ${row}
        Wait Until Keyword Succeeds    10x    1.0 sec    Order another Robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${OUTPUT_DIR}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close RobotSpareBin Browser
    Close Browser
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True

Close the annoying modal
    Click Button When Visible    //button[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath: //input[@type='number']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Element When Clickable    preview

Order the robot
    Wait Until Element Is Visible    robot-preview
    Click Element When Clickable    order
    Wait Until Element Is Visible    order-another

Download and store the result
    [Arguments]    ${row}
    ${pdf_name}=    Catenate    SEPARATOR=    ${row}[Order number]    .pdf
    ${pdf}=    Catenate    SEPARATOR=${/}    ${PDF_TEMP_OUTPUT_DIRECTORY}    ${pdf_name}

    ${receipt}=    Catenate    SEPARATOR=${/}    ${OUTPUT_DIR}    receipt.pdf
    ${image}=    Catenate    SEPARATOR=${/}    ${OUTPUT_DIR}    image.png

    ${files}=    Create List
    ...    ${receipt}
    ...    ${image}

    # ${order_html}=    Get Element Attribute    xpath://div[contains(@class, "container main-container")]    outerHTML
    ${order_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${order_html}    ${receipt}
    ${screenshot_html}=    Get Element Attribute    robot-preview-image    outerHTML
    Screenshot    robot-preview-image    ${image}

    # Open PDF    /tmp/sample.pdf
    # Add Files To Pdf    ${files}    merged-doc.pdf
    # Save PDF    /tmp/output.pdf
    # Close pdf    path/to/the/pdf/file.pdf
    Add Files To Pdf    ${files}    ${pdf}

Order another Robot
    Click Button    order-another

Archive output PDFs
    ${zip_file_name}=    PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}
