# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os
import xmltodict
import mlx.traceability
from pathlib import Path
from datetime import datetime

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

projectDir = str(os.getenv('PROJECT_DIR'))
project = Path(projectDir).joinpath('name-version.txt').read_text().split(':')[0].strip()
copyright = '2023, exqudens'
author = 'exqudens'
release = Path(projectDir).joinpath('name-version.txt').read_text().split(':')[1].strip()
rst_prolog = '.. |project| replace:: ' + project + '\n\n'
if str(os.getenv('PROJECT_TEST_REPORT_FILES')) != 'None':
    for f in str(os.getenv('PROJECT_TEST_REPORT_FILES')).split(';'):
        xmlEntry = xmltodict.parse(Path(f).read_text())
        name = xmlEntry['testsuites']['testsuite']['@name']
        name += '.'
        name += xmlEntry['testsuites']['testsuite']['testcase']['@name']
        timestamp = datetime.strptime(
            xmlEntry['testsuites']['testsuite']['testcase']['@timestamp'],
            '%Y-%m-%dT%H:%M:%S.%f'
        )
        timestampDate = '{}-{:02d}-{:02d}'.format(
            timestamp.year,
            timestamp.month,
            timestamp.day
        )
        rst_prolog += '.. |' + name + '.date' + '| replace:: ' + timestampDate + '\n\n'
        status = 'PASSED'
        if (
            int(xmlEntry['testsuites']['testsuite']['@failures']) > 0
            or int(xmlEntry['testsuites']['testsuite']['@errors']) > 0
        ):
            status = 'FAILED'
        if (
                int(xmlEntry['testsuites']['testsuite']['@disabled']) > 0
                or int(xmlEntry['testsuites']['testsuite']['@skipped']) > 0
        ):
            status = 'SKIPPED'
        rst_prolog += '.. |' + name + '.status' + '| replace:: ' + status + '\n\n'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'linuxdoc.rstFlatTable',
    'breathe',
    'mlx.traceability',
    'docxbuilder',
    'rst2pdf.pdfbuilder'
]

templates_path = []
exclude_patterns = []

# -- Options for TRACEABILITY output -------------------------------------------------
# https://melexis.github.io/sphinx-traceability-extension/configuration.html#configuration

traceability_render_relationship_per_item = True
traceability_notifications = {
    'undefined-reference': 'UNDEFINED_REFERENCE'
}

# -- Options for BREATHE -------------------------------------------------
# https://breathe.readthedocs.io/en/latest/quickstart.html

breathe_projects = {
    'main': str(Path(projectDir).joinpath('build', 'doxygen', 'main', 'xml')),
    'test': str(Path(projectDir).joinpath('build', 'doxygen', 'test', 'xml'))
}
breathe_default_project = "main"

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = [str(Path(mlx.traceability.__file__).parent.joinpath('assets'))]

# -- Options for DOCX output -------------------------------------------------
# https://docxbuilder.readthedocs.io/en/latest/docxbuilder.html#usage

docx_documents = [
    (
        'index',
        str(os.getenv('PROJECT_TITLE')).replace(' ', '_') + '.docx',
        {
            'title': project + ' documentation',
            'created': datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
            'subject': project + '-' + release,
            'keywords': ['sphinx']
        },
        False
    )
]
docx_coverpage = False
#docx_pagebreak_before_section = 1

# -- Options for PDF output -------------------------------------------------
# https://rst2pdf.org/static/manual.html#sphinx

pdf_documents = [
    ('index', str(os.getenv('PROJECT_TITLE')).replace(' ', '_'), release, author)
]
pdf_use_toc = True
pdf_use_coverpage = False
#pdf_break_level = 2
#pdf_breakside = 'any'
