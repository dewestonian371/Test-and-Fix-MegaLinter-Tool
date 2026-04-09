# Test MegaLinter Hybride

Ce fichier contient à la fois du Markdown et du XML.

## Section Markdown

Voici du texte en **gras**, en *italique*, et du `code`.

### Liste Markdown
- Item 1
- Item 2
- Item 3

## Section XML

Voici un bloc de code XML qui sera analysé par MegaLinter :

```xml
<root version="1.0">
  <config>
    <key name="test">valeur</key>
    <item>élément 1</item>
    <item>élément 2</item>
  </config>
</root>
```

## Autre bloc XML

```xml
<data>
  <record id="1">
    <field>Content here</field>
  </record>
</data>
```

---

> Ce fichier est utilisé pour tester le workflow MegaLinter sur des fichiers hybrides MD/XML.