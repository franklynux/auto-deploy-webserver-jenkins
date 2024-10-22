import unittest
from bs4 import BeautifulSoup
import os

class TestWebsite(unittest.TestCase):
    def setUp(self):
        # Assuming the HTML files are in a directory named 'html'
        self.html_dir = '/var/www/html'
    
    def test_index_html_exists(self):
        self.assertTrue(os.path.exists(os.path.join(self.html_dir, 'index.html')), "index.html file does not exist")
    
    def test_index_html_structure(self):
        with open(os.path.join(self.html_dir, 'index.html'), 'r') as file:
            content = file.read()
            soup = BeautifulSoup(content, 'html.parser')
            
            # Check if there's a title
            self.assertIsNotNone(soup.title, "No title tag found in index.html")
            
            # Check if there's a header
            self.assertIsNotNone(soup.header, "No header tag found in index.html")
            
            # Check if there's a main content area
            self.assertIsNotNone(soup.find('main'), "No main content area found in index.html")
            
            # Check if there's a footer
            self.assertIsNotNone(soup.footer, "No footer tag found in index.html")
    
    def test_css_file_exists(self):
        self.assertTrue(os.path.exists(os.path.join(self.html_dir, 'css', 'tooplate-barista-cafe.css')), "CSS file does not exist")
    
    def test_js_file_exists(self):
        self.assertTrue(os.path.exists(os.path.join(self.html_dir, 'js', 'custom.js')), "JavaScript file does not exist")
    
    def test_content(self):
        with open(os.path.join(self.html_dir, 'index.html'), 'r') as file:
            content = file.read()
            soup = BeautifulSoup(content, 'html.parser')
            
            # Check if the cafe name is in the header
            header_text = soup.header.get_text()
            self.assertIn("Barista Cafe", header_text, "Cafe name not found in header")
            
            # Check if there's a menu section
            menu_section = soup.find('section', id='menu')
            self.assertIsNotNone(menu_section, "Menu section not found")
            
            # Check if there's a contact section
            contact_section = soup.find('section', id='contact')
            self.assertIsNotNone(contact_section, "Contact section not found")

if __name__ == '__main__':
    unittest.main()