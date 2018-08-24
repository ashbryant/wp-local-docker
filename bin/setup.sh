#!/bin/bash

# Purpose: WordPress provisioning script
# Source: https://ashbryant.com
# Author: Ash
#
# NOTE:
# Seeing as I'm new to bash & I don't know when I will be back to it...
# "&& \" This lets you do something based on whether the previous command completed successfully. Seeing as most of this requires that process is why I have it here.

# Location of some variables needed for setup
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.common.sh"

# check_depedencies - IF there is a wp-config file WP is already installed
if [ -f "/var/www/html/wp-config.php" ];
then

	output "Wordpress has already installed at \"$SOURCE_DIR\"." -i
	output "Do you want to reinstall? [y/n] " -e && \
	read REINSTALL

	if [ "y" = "$REINSTALL" ]
		then
			wp db reset --yes
			GLOBIGNORE='wp-cli.local.yml'
			rm -rf *

			output "Okay, all files have been removed. Try again." -s
		else
			output "Installation aborted." -e
			exit 1
	fi
	
else
	confirm_to_continue "Are you sure want to install Wordpress to \"$SOURCE_DIR\" [Yn]? "

	# Prepare_empty_dir "/var/www/html"
	rm -f "/var/www/html/.gitkeep"
	#check_empty_dir "/var/www/html" "Sorry, but \"$SOURCE_DIR\" is not empty, please backup your data before continue."
	output "# Running install scripts..." -i

	# Generate random 12 character password
	WP_USER_PASSWORD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12) && \

	# Ask for the type of installation
	output "Do you want a multisite installation? [y/n] " -w && \
	read MULTISITE

	# Install WordPress
	# Download English Version of WordPress
	wp core download --locale=en_GB && \

	# Config the DB connection
	wp core config --dbhost=mysql --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASSWORD && \

	if [ "y" = "$MULTISITE" ]
		then
			wp core multisite-install --prompt
		else
			wp core install --url="$DOMAIN_NAME"  --title="$BLOG_TITLE" --admin_user="$WP_USER" --admin_password="$WP_USER_PASSWORD" --admin_email="$WP_USER_EMAIL" 
	fi

	# TODO: Copy password to clipboard, can't get it to work right now
	# echo "Admin password = " $password | cat ~/.ssh/id_rsa.pub | pbcopy && \


	# Set the blog description
	wp option update blogdescription "$BLOG_DESCRIPTION" && \

	# Set the time zone
	wp option update timezone_string "Europe/London" && \

	# Set Date format (21st August 2018)
	wp option update date_format "jS F Y" && \

	# Set time format (10:00 am)
	wp option update time_format "g:i a" && \

	# Set Create .htaccessfile and set pretty urls
	#touch /var/www/html/.htaccess
	#chmod 777 /var/www/html/.htaccess
	wp rewrite structure '/%postname%/' --hard && \
	wp rewrite flush --hard && \

	# Update translations
	wp language core update && \



	# Ask to remove default content ?
	output "Do you want to remove all of the default content? (aka a blank install) [y/n] " -w && \
	read EMPTY_CONTENT

	if [ "y" = "$EMPTY_CONTENT" ]
		then
			# Remove all posts, comments, and terms
			wp site empty --yes && \

			# Remove plugins and themes
			wp plugin delete hello && \
			wp plugin delete akismet && \
			wp theme delete twentyfifteen && \
			wp theme delete twentysixteen && \

			# Remove widgets
			wp widget delete recent-posts-2 && \
			wp widget delete recent-comments-2 && \
			wp widget delete archives-2 && \
			wp widget delete search-2
			wp widget delete categories-2 && \
			wp widget delete meta-2
		else
			# Delete stock post 
			wp post delete 1 --force && \

			# Trash sample page, and 
			wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids) && \
			
			# Create Home, About Us, Blog & Contact Us pages
			wp post create --post_type=page --post_title='Home' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
			wp post create --post_type=page --post_title='About Us' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
			wp post create --post_type=page --post_title='Blog' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
			wp post create --post_type=page --post_title='Contact Us' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \

			# Set home page as front page
			wp option update show_on_front 'page' && \

			# Set home page to be the new page
			wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids) && \

			# Set blog page to be the new page
			wp option update page_for_posts $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=blog --field=ID --format=ids) && \

			# Create a navigation bar
			wp menu create "Main Nav" && \

			# Assign navigaiton to primary location
			# wp menu location assign main-navigation primary && \

			# Open the new website with Google Chrome
			#/usr/bin/open -a "/Applications/Google Chrome.app" "http://$DOMAIN_NAME/wp-admin" && \	

			# Delete stock themes
		    wp theme delete twentyfifteen && \
		    wp theme delete twentysixteen && \

			# Delete plugins
			wp plugin delete akismet && \
			wp plugin delete hello && \

			output "Do you want to install WooCommerce [Yn]?" -w && \
			read woocommerce

			if [ "$woocommerce" = "y" ]
				then
					wp plugin install woocommerce --activate
					# This is a WordPress plugin that adds several WP-CLI commands for generating fake WooCommerce data
					# https://github.com/metorikhq/wc-cyclone
					wp plugin install https://github.com/metorikhq/wc-cyclone/archive/master.zip --activate 

					# Create the WooCommerce pages
					wp post create --post_type=page --post_title='Shop' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
					wp post create --post_type=page --post_title='Cart' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
					wp post create --post_type=page --post_title='Checkout' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
					wp post create --post_type=page --post_title='My Account' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \
					wp post create --post_type=page --post_title='Terms and conditions' --post_status=publish --post_author=$(wp user get $WP_USER --field=ID --format=ids) && \

					# Set WooCommerce those up correctly in WC Settings > Advanced
					wp option update woocommerce_shop_page_id $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename='shop' --field=ID --format=ids) && \
					wp option update woocommerce_cart_page_id $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename='cart' --field=ID --format=ids) && \
					wp option update woocommerce_checkout_page_id $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename='checkout' --field=ID --format=ids) && \
					wp option update woocommerce_myaccount_page_id $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename='my-account' --field=ID --format=ids) && \
					wp option update woocommerce_terms_page_id $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename='terms-and-conditions' --field=ID --format=ids) && \

					# Install & activate the default WC theme
					wp theme install storefront --activate

					# Install & activate the most used WC plugins
					wp plugin install woocommerce-sequential-order-numbers search-by-sku-for-woocommerce woocommerce-gateway-paypal-powered-by-braintree woocommerce-pdf-invoices woocommerce-google-analytics-integration --activate

				else
					output "Ok, I am not going to install WooCommerce" -e
			fi

			#Download paid for plugins, install & activate them, then remove the zip files (Thanks https://goo.gl/ktysp5)
			wget -v -O acf-pro.zip "https://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=" && \
			wp plugin install acf-pro.zip --activate --allow-root && \
			rm acf-pro.zip && \

			wget -v -O gravityforms.zip "https://www.dropbox.com/s/2msjyeecr4294ml/gravityforms.zip" && \
			wp plugin install gravityforms.zip --activate --allow-root && \
			rm gravityforms.zip && \

			wget -v -O wp-migrate-db-pro.zip "https://www.dropbox.com/s/15q870ho0csh8bf/wp-migrate-db-pro.zip" && \
			wp plugin install wp-migrate-db-pro.zip --activate --allow-root && \
			rm wp-migrate-db-pro.zip && \

			# Update all plugins
			wp plugin update --all && \

			# Install plugins
			wp plugin install wpcore && \
			wp plugin install adminimize && \
			wp plugin install antispam-bee && \
			wp plugin install broken-link-checker && \
			wp plugin install cookie-law-info && \
			wp plugin install custom-post-type-ui && \
			wp plugin install duplicate-post && \
			wp plugin install eps-301-redirects && \
			wp plugin install elasticpress && \
			wp plugin install enable-media-replace && \
			wp plugin install google-analytics-for-wordpress && \
			wp plugin install wp-mail-smtp && \
			wp plugin install wp-maintenance-mode && \
			wp plugin install really-simple-ssl && \
			wp plugin install regenerate-thumbnails && \
			wp plugin install wp-smushit && \
			wp plugin install swift-performance-lite && \
			wp plugin install stream && \
			wp plugin install user-switching && \
			wp plugin install wordpress-seo && \
			wp plugin install wp-helpers && \

			# Activate plugins
			wp plugin activate adminimize cookie-law-info duplicate-post enable-media-replace wordpress-seo wpcore wp-helpers

			# Activate plugin in entire multisite network
			# wp plugin activate hello --network

			# Discourage search engines
			# wp option update blog_public 0

	fi

	clear

	echo "=================================================================================="
	output " Wordpress is installed successfully." -s && \
	echo "=================================================================================="
	echo ""
	echo " WordPress install complete. Your username/password is listed below."
	echo ""
	echo " Please add this to your hostfile:	127.0.0.1	$DOMAIN_NAME"
	echo ""
	echo " Login to $BLOG_TITLE at: http://$DOMAIN_NAME/wp-admin"
	echo ""
	echo " Username: $WP_USER"
	echo " Password: $WP_USER_PASSWORD"
	echo ""
	echo " DATEBASE DETAILS"
	echo " Database Name: 	$MYSQL_DATABASE"
	echo " Database Username: 	$MYSQL_USER"
	echo " Database Password: 	$MYSQL_PASSWORD"
	echo ""
	echo "=================================================================================="

	touch /var/www/html/.gitkeep
fi
